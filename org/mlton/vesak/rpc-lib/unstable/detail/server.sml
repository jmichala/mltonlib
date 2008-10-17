(* Copyright (C) 2008 Vesa Karvonen
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

structure Server :> SERVER = struct
   open SocketEvents Async Protocol

   structure ProcMap = struct
      type t = (Fingerprint.t,
                Token.t -> (Unit.t, Socket.active) monad) HashMap.t

      fun new () =
          HashMap.new
           {eq = (op =),
            hash = Word32.toWord o Fingerprint.toWord32}

      val sendExn = send Exn.t

      fun add entries (signature' as (dom, cod, name)) = let
         val fingerprint = Fingerprint.fromSignature signature'
         val recvDom = recv dom
         val sendCod = send cod
         open Reply
      in
         fn f =>
            case HashMap.find entries fingerprint
             of SOME _ => fails ["fingerprint of ", name, " already in use"]
              | NONE =>
                (HashMap.insert entries)
                 (fingerprint,
                  fn token =>
                     recvDom >>= (fn x =>
                     try (fn () => f x,
                          fn y =>
                             send (RESULT token) >>= (fn () =>
                             sendCod y),
                          fn e =>
                             send (EXN token) >>= (fn () =>
                             sendExn e))))
      end
   end

   structure TCP = struct
      structure Opts = struct
         datatype t = IN
          of {name : String.t
            , port : Int.t
            , numAccepts : Int.t Option.t
            , tcpNoDelay : Bool.t
            , serverError : Exn.t Effect.t
            , closed : Unit.t Effect.t
            , accept : {addr : INetSock.sock_addr} UnPr.t
            , protocolMismatch :
               {addr : INetSock.sock_addr,
                version : Protocol.Version.t} Effect.t
            , connected : {addr : INetSock.sock_addr} Effect.t
            , unknownProc :
               {addr : INetSock.sock_addr,
                fingerprint : Protocol.Fingerprint.t} Effect.t
            , protocolError :
               {addr : INetSock.sock_addr,
                error : Exn.t} Effect.t
            , disconnected : {addr : INetSock.sock_addr} Effect.t}

         datatype 'a opt = OPT of {get : t -> 'a, set : 'a -> t UnOp.t}

         val default : t =
             IN {name = "127.0.0.1"
               , port = 45678
               , numAccepts = NONE
               , tcpNoDelay = false
               , serverError = ignore
               , closed = ignore
               , accept = const true
               , protocolMismatch = ignore
               , connected = ignore
               , unknownProc = ignore
               , protocolError = ignore
               , disconnected = ignore}

         fun mk get set =
             OPT {set = fn value =>
                           fn IN {name
                                , port
                                , numAccepts
                                , tcpNoDelay
                                , serverError
                                , closed
                                , accept
                                , protocolMismatch
                                , connected
                                , unknownProc
                                , protocolError
                                , disconnected} => let
                                 val opts =
                                     {name = ref name
                                    , port = ref port
                                    , numAccepts = ref numAccepts
                                    , tcpNoDelay = ref tcpNoDelay
                                    , serverError = ref serverError
                                    , closed = ref closed
                                    , accept = ref accept
                                    , protocolMismatch = ref protocolMismatch
                                    , connected = ref connected
                                    , unknownProc = ref unknownProc
                                    , protocolError = ref protocolError
                                    , disconnected = ref disconnected}
                                 fun get field = !(field opts)
                              in
                                 set opts := value
                               ; IN {name = get #name
                                   , port = get #port
                                   , numAccepts = get #numAccepts
                                   , tcpNoDelay = get #tcpNoDelay
                                   , serverError = get #serverError
                                   , closed = get #closed
                                   , accept = get #accept
                                   , protocolMismatch = get #protocolMismatch
                                   , connected = get #connected
                                   , unknownProc = get #unknownProc
                                   , protocolError = get #protocolError
                                   , disconnected = get #disconnected}
                              end,
                  get = fn IN r => get r}

         val name = mk #name #name
         val port = mk #port #port
         val numAccepts = mk #numAccepts #numAccepts
         val tcpNoDelay = mk #tcpNoDelay #tcpNoDelay
         val serverError = mk #serverError #serverError
         val closed = mk #closed #closed
         val accept = mk #accept #accept
         val protocolMismatch = mk #protocolMismatch #protocolMismatch
         val connected = mk #connected #connected
         val unknownProc = mk #unknownProc #unknownProc
         val protocolError = mk #protocolError #protocolError
         val disconnected = mk #disconnected #disconnected

         fun opts & (OPT {set, ...}, value) = set value opts
         val op := = id
      end

      fun start entries
                (Opts.IN {name
                        , port
                        , numAccepts
                        , tcpNoDelay
                        , serverError
                        , closed
                        , accept
                        , protocolMismatch
                        , connected
                        , unknownProc
                        , protocolError
                        , disconnected}) = let
         fun serve addr =
             Request.recv >>= (fn req =>
             case req
              of Request.CALL {token, fingerprint} =>
                 case HashMap.find entries fingerprint
                  of NONE =>
                     (unknownProc {addr = addr, fingerprint = fingerprint}
                    ; skip >>= (fn () =>
                      Reply.send (Reply.UNKNOWN token) >>= (fn () =>
                      serve addr)))
                   | SOME procedure =>
                     procedure token >>= (fn () =>
                     serve addr))

         fun negotiate addr =
             Version.send Version.current >>= (fn () =>
             Version.recv >>= (fn version =>
             if version <> Version.current
             then (protocolMismatch {addr = addr, version = version}
                 ; return ())
             else (connected {addr = addr}
                 ; serve addr)))

         fun listen numAccepts =
             if SOME 0 = numAccepts
             then return ()
             else SocketEvents.sockEvt OS.IO.pollIn >>= (fn socket =>
                  case Socket.acceptNB socket
                   of NONE => error (Fail "acceptNB returned NONE")
                    | SOME (socket, addr) =>
                      (if not (accept {addr = addr})
                       then (Socket.close socket
                           ; listen numAccepts)
                       else (INetSock.TCP.setNODELAY (socket, tcpNoDelay)
                           ; (when (negotiate addr socket))
                              (fn r =>
                                  (Socket.close socket
                                 ; case r
                                    of INR () => ()
                                     | INL Closed => ()
                                     | INL e =>
                                       protocolError {addr = addr, error = e}
                                 ; disconnected {addr = addr}))
                           ; listen (Option.map (fn n => n-1) numAccepts))))

         val socket = INetSock.TCP.socket ()
      in
         (Socket.bind
           (socket,
            INetSock.toAddr
             (NetHostDB.addr
               (valOf (NetHostDB.getByName name)),
              port))
        ; Socket.listen (socket, 16))
         handle e => (Socket.close socket ; raise e)
       ; (when (listen numAccepts socket))
          (fn r =>
              (Socket.close socket
             ; case r
                of INL e  => serverError e
                 | INR () => ()
             ; closed ()))
      end
   end

   fun run () = PollLoop.run Handler.runAll
end
