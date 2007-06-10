(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(**
 * Signature for a type-indexed function for generating random values of
 * any type.  The design is inspired by the
 * [http://www.cs.chalmers.se/~rjmh/QuickCheck/ QuickCheck] library by
 * Koen Claessen and John Hughes.
 *)
signature ARBITRARY = sig
   structure Arbitrary : EXT_GENERIC_INDEX

   structure RandomGen : RANDOM_GEN
   (** The underlying random value generator. *)

   val arbitrary : ('a, 'x) Arbitrary.t -> 'a RandomGen.t
   (** Extracts the random value generator. *)

   val withGen : 'a RandomGen.t -> ('a, 'x) Arbitrary.t UnOp.t
   (** Functionally updates the random value generator. *)
end

signature ARBITRARY_GENERIC = sig
   include ARBITRARY EXT_GENERIC
   sharing Arbitrary = Index
end

signature WITH_ARBITRARY_DOM = sig
   structure Outer : EXT_GENERIC
   structure TypeInfo : TYPE_INFO
   sharing Outer.Index = TypeInfo.TypeInfo
   structure RandomGen : RANDOM_GEN
end