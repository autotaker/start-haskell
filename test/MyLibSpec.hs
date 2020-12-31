module MyLibSpec where

import Test.Hspec (Spec, describe, it, shouldBe)

spec :: Spec
spec = describe "trivial" $ do
  it "True should be True" $ do
    True `shouldBe` True
