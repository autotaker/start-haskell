module AuthSpec where

import Auth (HasUserRepository (userRepositoryL), UserRepository (UserRepository, _createUser, _findByUsername), signin)
import Lens.Micro.Platform (makeLenses)
import RIO (runRIO, throwString, (^.))
import Test.Hspec (Spec, context, describe, it, shouldReturn)
import User (User (User), username)

newtype Env = Env {_userRepository :: UserRepository Env}

makeLenses ''Env

instance HasUserRepository Env where
  userRepositoryL = userRepository

userRepositoryMock :: UserRepository env
userRepositoryMock =
  UserRepository
    { _findByUsername = \user ->
        if user == "user1"
          then pure $ Just user1
          else pure Nothing,
      _createUser = \user ->
        if user ^. username == "user1"
          then throwString "user1 is already registered"
          else pure ()
    }

user1 :: User
user1 = User "user1" "password1"

spec :: Spec
spec = do
  describe "signin" $ do
    context "ユーザ名とパスワードが一致する時" $ do
      it "`Just user`を返す" $ do
        -- 準備：ユーザが一人だけ登録されたデータベースのモック
        let env = Env userRepositoryMock
        -- 実行 & 検証
        runRIO env (signin "user1" "password1")
          `shouldReturn` Just user1
