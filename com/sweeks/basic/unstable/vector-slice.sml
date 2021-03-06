(* Copyright (C) 2006 Stephen Weeks.
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)
structure VectorSlice: VECTOR_SLICE = struct

   structure Slice = struct

      type 'a t = 'a VectorSlice.slice
      type 'a elem = 'a

      local
         open VectorSlice
      in
         val full = full
         val size = length
         val sub = sub
      end

      fun base s = let
         val (v, i, _) = VectorSlice.base s
      in
         (v, {start = i})
      end

      fun slice (s, {size, start}) = VectorSlice.subslice (s, start, SOME size)
   end

   open Slice

   structure S = Slice (structure Base = Vector
                        open Slice)

   open S

end
                                  
