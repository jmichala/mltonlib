(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

functor MkMonad (MonadCore : MONAD_CORE) : MONAD = struct
   infix >> >>& >>* >>= >>@
   open MonadCore
   type 'a func = 'a monad
   fun map f aM = aM >>= return o f
   type 'a monad_ex = 'a monad
   fun aM >>* bM = aM >>= (fn a => bM >>= Fn.<\ (a, return))
   fun fM >>@ aM = map Fn.\> (fM >>* aM)
   fun aM >>& bM = map Product.& (aM >>* bM)
   fun aM >> bM = map #2 (aM >>* bM)
   fun seq [] = return []
     | seq (xM::xMs) = map op :: (xM >>* seq xMs)
end

functor MkMonadP (MonadPCore : MONADP_CORE) : MONADP = struct
   structure Monad = MkMonad (MonadPCore)
   open Monad MonadPCore
   type 'a monadp_ex = 'a monad
   fun sum [] = zero | sum [x] = x | sum (x::xs) = plus (x, sum xs)
end
