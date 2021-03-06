(* Copyright (C) 2006 Stephen Weeks.
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)
local
   open Basis
in
   structure Int = Int (Int)
   structure Int8 = Int (Int8)
   structure Int16 = Int (Int16)
   structure Int32 = Int (Int32)
   structure Int64 = Int (Int64)
   structure LargeInt = Int (LargeInt)
   structure Position = Int (Position)
end
