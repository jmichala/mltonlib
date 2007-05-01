(* Copyright (C) 2006-2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(* Minimal modules for bootstrapping. *)

structure Void = struct abstype t = T with fun void T = void T end end
structure Exn = struct type t = exn end
structure Fn = struct type ('a, 'b) t = 'a -> 'b end
structure Unit = struct type t = unit end
structure Bool = struct
   open BasisBool
   type t = bool
   fun isFalse b = b = false
   fun isTrue b = b = true
end
structure Char = struct open BasisChar type t = char end
structure Option = struct open BasisOption type 'a t = 'a option end
structure String = struct open BasisString type t = string end
structure Int = struct open BasisInt type t = int end
structure LargeInt = struct open BasisLargeInt type t = int end
structure Word = struct open BasisWord type t = word end
structure LargeWord = struct open BasisLargeWord type t = word end
structure LargeReal = struct open BasisLargeReal type t = real end
structure Word8Vector = struct open BasisWord8Vector type t = vector end
structure Array = struct open BasisArray type 'a t = 'a array end
structure ArraySlice = struct open BasisArraySlice type 'a t = 'a slice end
structure Vector = struct open BasisVector type 'a t = 'a vector end
structure VectorSlice = struct open BasisVectorSlice type 'a t = 'a slice end
structure List = struct open BasisList type 'a t = 'a list end
structure Effect = struct type 'a t = 'a -> Unit.t end
structure Order = struct datatype order = datatype order type t = order end
structure Pair = struct
   type ('a, 'b) pair = 'a * 'b
   type ('a, 'b) t = ('a, 'b) pair
end
structure Product = struct
   datatype ('a, 'b) product = & of 'a * 'b
   type ('a, 'b) t = ('a, 'b) product
end
structure Ref = struct type 'a t = 'a ref end
structure Sum = struct
   datatype ('a, 'b) sum = INL of 'a | INR of 'b
   type('a, 'b) t = ('a, 'b) sum
end
structure Sq = struct type 'a t = 'a * 'a end
structure Thunk = struct type 'a t = Unit.t -> 'a end
structure UnOp = struct type 'a t = 'a -> 'a end
structure UnPr = struct type 'a t = 'a -> Bool.t end
structure Fix = struct type 'a t = 'a UnOp.t -> 'a end
structure Reader = struct type ('a, 'b) t = 'b -> ('a * 'b) Option.t end
structure Writer = struct type ('a, 'b) t = 'a * 'b -> 'b end
structure Cmp = struct type 'a t = 'a Sq.t -> Order.t end
structure BinOp = struct type 'a t = 'a Sq.t -> 'a end
structure BinPr = struct type 'a t = 'a Sq.t UnPr.t end
structure Emb = struct type ('a, 'b) t = ('a -> 'b) * ('b -> 'a Option.t) end
structure Iso = struct type ('a, 'b) t = ('a -> 'b) * ('b -> 'a) end
structure ShiftOp = struct type 'a t = 'a * Word.t -> 'a end
structure BinFn = struct type ('a, 'b) t = 'a Sq.t -> 'b end
structure IEEEReal = BasisIEEEReal
structure Univ = struct exception Univ end
