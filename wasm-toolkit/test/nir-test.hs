{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}

import Bindings.Binaryen.Raw
import qualified Data.ByteString as BS
import Foreign.ForeignPtr
import Language.WebAssembly.NIR

main :: IO ()
main = do
  m <-
    marshalModule $
    emptyModule
      { functionTypeMap = [("func_type", FunctionType I32 [I32])]
      , functionMap =
          [ ( "func"
            , Function "func_type" [I32] $
              CFG $
              RelooperRun
                "block_entry"
                [ ( "block_entry"
                  , RelooperBlock
                      (AddBlock Nop)
                      [ AddBranch
                          "block_0"
                          (Binary EqInt32 (GetLocal 0 I32) (ConstI32 0))
                          Null
                      , AddBranch "block_def" Null Null
                      ])
                , ( "block_0"
                  , RelooperBlock
                      (AddBlock (Block "" [Return $ ConstI32 0] I32))
                      [])
                , ("block_def", RelooperBlock (AddBlock (ConstI32 233)) [])
                ]
                (Just 1))
          ]
      }
  fptr <- mallocForeignPtrBytes 1000000
  (s, _) <-
    withForeignPtr fptr $ \p -> do
      s <- c_BinaryenModuleWrite m p 1000000
      bs <- BS.packCStringLen (p, fromIntegral s)
      finalizeForeignPtr fptr
      pure (s, bs)
  print s
  c_BinaryenModulePrint m
  c_BinaryenModuleValidate m >>= print
  c_BinaryenModuleDispose m
