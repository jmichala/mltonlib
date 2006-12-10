(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(* Extended mono sequence modules common to all compilers *)

structure Word8Vector = MkMonoVectorExt (Word8Vector)
structure Word8VectorSlice =
   MkMonoVectorSliceExt (structure MonoVectorSlice = Word8VectorSlice)
structure Word8Array = MkMonoArrayExt (structure MonoArray = Word8Array
                                       structure MonoVector = Word8Vector)
structure Word8ArraySlice =
   MkMonoArraySliceExt (structure MonoArraySlice = Word8ArraySlice)

structure Text = MkTextExt (Text)
structure Char = Text.Char
structure CharArray = Text.CharArray
structure CharArraySlice = Text.CharArraySlice
structure CharVector = Text.CharVector
structure CharVectorSlice = Text.CharVectorSlice
structure String = Text.String
structure Substring = Text.Substring