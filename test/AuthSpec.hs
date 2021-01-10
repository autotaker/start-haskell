module AuthSpec where

import Auth (signin)
import Test.Hspec (Spec, context, describe, it, shouldReturn)
import User (User (User))
import UserRepository (createUser)

spec :: Spec
spec = do
  describe "signin" $ do
    context "ユーザ名とパスワードが一致する時" $ do
      it "`Just user`を返す" $ do
        -- 準備：ユーザ名とパスワードをデータベースに登録する
        let user1 = User "user1" "password1"
        createUser user1
        -- 実行 & 検証
        signin "user1" "password1" `shouldReturn` Just user1
