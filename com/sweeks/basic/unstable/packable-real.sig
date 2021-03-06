(* Copyright (C) 2006 Stephen Weeks.
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)
signature PACKABLE_REAL = sig

   include REAL

   val ofBytes: Word8.t Vector.t * Endian.t -> t
   val subArr: Word8.t Array.t * Int.t * Endian.t -> t
   val subVec: Word8.t Vector.t * Int.t * Endian.t -> t
   val toBytes: t * Endian.t -> Word8.t vector
   val update: Word8.t Array.t * Int.t * t * Endian.t -> Unit.t

end
