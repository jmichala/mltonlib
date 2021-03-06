(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(*
 * An implementation of a type-indexed function for pretty printing values
 * of arbitrary SML datatypes.  See
 *
 *   http://mlton.org/TypeIndexedValues
 *
 * for further discussion.
 *)

(* XXX show sharing *)
(* XXX pretty printing could use some tuning *)
(* XXX parameters for pretty printing? *)
(* XXX parameters for depth, length, etc... for showing only partial data *)

signature SHOW = sig
   type 'a show_t
   type 'a show_s
   type ('a, 'k) show_p

   val layout : 'a show_t -> 'a -> Prettier.t
   (** Extracts the prettifying function. *)

   val show : Int.t Option.t -> 'a show_t -> 'a -> String.t
   (** {show m t = Prettier.pretty m o layout t} *)
end

functor LiftShow
           (include SHOW
            type 'a t
            type 'a s
            type ('a, 'k) p
            val liftT : ('a show_t, 'a t) Lift.t Thunk.t) : SHOW = struct
   type 'a show_t = 'a t
   type 'a show_s = 'a s
   type ('a, 'k) show_p = ('a, 'k) p
   val layout = fn ? => Lift.get liftT layout ?
   val show   = fn m => Lift.get liftT (show m)
end

structure Show :> sig
   include TYPE SHOW
   sharing type show_t = t
   sharing type show_s = s
   sharing type show_p = p
end = struct
   local
      open Prettier
      type u = Bool.t * t
      fun atomic    doc = (true,  doc)
      fun nonAtomic doc = (false, doc)
      val uop : t UnOp.t -> u UnOp.t = id <\ Pair.map
      val bop : t BinOp.t -> u BinOp.t =
          fn f => nonAtomic o f o Pair.map (Sq.mk Pair.snd)
   in
      type u = u

      val parens       = (1, (lparen,   rparen))
      val hashParens   = (2, (txt "#(", rparen))
      val braces       = (1, (lbrace,   rbrace))
      val brackets     = (1, (lbracket, rbracket))
      val hashBrackets = (2, (txt "#[", rbracket))

      val comma  = atomic comma
      val equals = atomic equals

      val txt = atomic o txt
      fun surround (n, p) = atomic o group o nest n o enclose p o Pair.snd
      fun atomize (d as (a, _)) = if a then d else surround parens d
      val punctuate = fn (_, s) => punctuate s o map Pair.snd
      val fill = fn ? => nonAtomic (vsep ?)
      val group = uop group
      val nest = uop o nest
      val op <^> = fn ((al, dl), (ar, dr)) => (al andalso ar, dl <^> dr)
      val op <$> = bop op <$>
      val op </> = bop op </>
   end

   local
      open TypeSupport
   in
      val C = C
      val l2s = labelToString
      val c2s = constructorToString
   end

   type 'a t = exn list * 'a -> u
   type 'a s = 'a t
   type ('a, 'k) p = 'a t
   type 'a show_t = 'a t
   type 'a show_s = 'a s
   type ('a, 'k) show_p = ('a, 'k) p

   fun layout t x = Pair.snd (t ([], x))
   fun show m t = Prettier.pretty m o layout t

   fun inj b a2b = b o Pair.map (id, a2b)
   fun iso b = inj b o Iso.to
   val isoProduct = iso
   val isoSum = iso

   fun (l *` r) (env, a & b) = l (env, a) <^> comma <$> r (env, b)

   val T = id
   fun R label = let
      val txtLabel = txt (l2s label)
      fun fmt t ? = group (nest 1 (txtLabel </> equals </> t ?))
   in
      fmt
   end

   fun tuple t = surround parens o t
   fun record t = surround braces o t

   fun l +` r = fn (env, INL a) => l (env, a)
                 | (env, INR b) => r (env, b)

   fun C0 ctor = const (txt (c2s ctor))
   fun C1 ctor = let
      val txtCtor = txt (c2s ctor)
   in
      fn t => fn ? => nest 1 (group (txtCtor <$> atomize (t ?)))
   end

   val data = id

   val Y = Tie.function

   val exn : exn t ref =
       ref (txt o "#" <\ op ^ o General.exnName o #2)
   fun regExn t (_, prj) =
       Ref.modify (fn exn => fn (env, e) =>
                      case prj e of
                         NONE => exn (env, e)
                       | SOME x => t (env, x)) exn
   val exn = fn ? => !exn ?

   val txtAs = txt "as"
   fun cyclic t = let
      exception E of ''a * bool ref
   in
      fn (env, v : ''a) => let
         val idx = Int.toString o length
         fun lp (E (v', c)::env) =
             if v' <> v then
                lp env
             else
                (c := false ; txt ("#"^idx env))
           | lp (_::env) = lp env
           | lp [] = let
            val c = ref true
            val r = t (E (v, c)::env, v)
         in
            if !c then
               r
            else
               txt ("#"^idx env) </> txtAs </> r
         end
      in
         lp env
      end
   end
   fun aggregate style toL t (env, a) =
       surround style o fill o punctuate comma o map (curry t env) |< toL a

   val ctorRef = C "ref"
   fun refc  ? = cyclic o flip inj ! |< C1 ctorRef ?
   fun array ? = cyclic |< aggregate hashParens Array.toList ?

   fun vector ? = aggregate hashBrackets Vector.toList ?

   fun list ? = aggregate brackets id ?

   val txtFn = txt "#fn"
   fun _ --> _ = const txtFn

   local
      open Prettier
      val toLit = txt o String.toString
      val nlbs = txt "\\n\\"
   in
      fun string (_, s) =
          (true,
           group o dquotes |< choice
              {wide = toLit s,
               narrow = lazy (fn () =>
                                 List.foldl1 (fn (x, s) =>
                                                 s <^> nlbs <$> backslash <^> x)
                                             (map toLit
                                                  (String.fields
                                                      (#"\n" <\ op =) s)))})
   end

   fun mk toS : 'a t = txt o toS o Pair.snd
   fun enc l r toS x = concat [l, toS x, r]
   fun mkWord toString = mk ("0wx" <\ op ^ o toString)

   val bool = mk Bool.toString
   val char = mk (enc "#\"" "\"" Char.toString)
   val int  = mk Int.toString
   val real = mk Real.toString
   val unit = mk (Thunk.mk "()")
   val word = mkWord Word.toString

   val largeInt  = mk LargeInt.toString
   val largeReal = mk LargeReal.toString
   val largeWord = mkWord LargeWord.toString

   val word8  = mkWord Word8.toString
   val word16 = mkWord Word16.toString
   val word32 = mkWord Word32.toString
   val word64 = mkWord Word64.toString
end
