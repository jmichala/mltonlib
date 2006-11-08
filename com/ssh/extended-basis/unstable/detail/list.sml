(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

(**
 * Extended {List :> LIST} structure.
 *)
structure List : LIST = struct
   open List
   type 'a t = 'a list
   val sub = nth
end
