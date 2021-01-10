module AuthSpec where

import Auth (HasUserRepository (userRepositoryL), UserRepository (UserRepository, _createUser, _findByUsername), signin)
import Lens.Micro.Platform (makeLenses)
import RIO (runRIO, throwString, view)
import Test.Hspec (Spec, context, describe, it, shouldReturn)
import Test.Method
  ( ArgsMatcher (args),
    anything,
    mockup,
    thenAction,
    thenReturn,
    when,
  )
import User (User (User), username)

newtype Env = Env {_userRepository :: UserRepository Env}

makeLenses ''Env

instance HasUserRepository Env where
  userRepositoryL = userRepository

userRepositoryMock :: UserRepository env
userRepositoryMock =
  UserRepository
    { _findByUsername = mockup $ do
        when (args (== "user1")) `thenReturn` Just user1
        when anything `thenReturn` Nothing,
      _createUser = mockup $ do
        when (args ((== "user1") . view username))
          `thenAction` throwString "user1 is already registered"
        when anything `thenReturn` ()
    }

-- 準備：ユーザが一人だけ登録されたデータベースのモック
env :: Env
env = Env userRepositoryMock

user1 :: User
user1 = User "user1" "password1"

spec :: Spec
spec = do
  describe "signin" $ do
    context "ユーザ名とパスワードが一致する時" $ do
      it "`Just user`を返す" $ do
        -- 実行 & 検証
        runRIO env (signin "user1" "password1")
          `shouldReturn` Just user1

    context "ユーザ名とパスワードが一致しない時" $ do
      it "`Nothing`を返す" $ do
        -- 実行 & 検証
        runRIO env (signin "user1" "invalid_password")
          `shouldReturn` Nothing

    context "ユーザが登録されていない場合" $ do
      it "`Nothing`を返す" $ do
        -- 実行 & 検証
        runRIO env (signin "user2" "password2")
          `shouldReturn` Nothing
