module AuthSpec where

import Auth (HasPasswordGenerator (passwordGeneratorL), HasUserRepository (userRepositoryL), PasswordGenerator (PasswordGenerator, _generate), UserRepository (UserRepository, _createUser, _findByUsername), createUser, signin, signup)
import Lens.Micro.Platform (makeLenses)
import RIO (MonadReader (local), runRIO, throwString, view, void, (%~))
import Test.Hspec (Spec, context, describe, it, shouldReturn, shouldSatisfy)
import Test.Method
  ( ArgsMatcher (args),
    anything,
    call,
    mockup,
    thenAction,
    thenReturn,
    times,
    watch,
    when,
    withMonitor_,
  )
import User (User (User), username)

data Env = Env
  { _userRepository :: UserRepository Env,
    _passwordGenerator :: PasswordGenerator Env
  }

makeLenses ''Env

instance HasUserRepository Env where
  userRepositoryL = userRepository

instance HasPasswordGenerator Env where
  passwordGeneratorL = passwordGenerator

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
env = Env userRepositoryMock passwordGeneratorMock

passwordGeneratorMock :: PasswordGenerator Env
passwordGeneratorMock =
  PasswordGenerator
    { _generate =
        mockup $
          when anything `thenReturn` "random_password"
    }

user1, user2, user2' :: User
user1 = User "user1" "password1"
user2 = User "user2" "password2"
user2' = User "user2" "random_password"

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

  describe "signup" $ do
    context "登録されていないユーザ名の時" $ do
      context "パスワードが空文字列の時" $ do
        it "ランダムなパスワードを生成し`Just user`を返す" $ do
          runRIO env (signup "user2" "")
            `shouldReturn` Just user2'
      context "パスワードが空文字列でない時" $ do
        it "`Just user`を返す" $ do
          runRIO env (signup "user2" "password2")
            `shouldReturn` Just user2

        it "`createUser user`を呼び出す" $ do
          logs <- runRIO env $
            -- `Monitor`を新しく作成し、記録されたメソッド呼び出しのログを返す
            withMonitor_ $ \monitor ->
              -- `createUser`メソッドの呼び出しを監視する
              local (userRepositoryL . createUser %~ watch monitor) $
                void $ signup "user2" "password2"
          -- ログ中で引数が`user2`と等しい呼び出しがちょうど一回あることをアサート
          logs `shouldSatisfy` (== 1) `times` call (args (== user2))

    context "登録ずみユーザ名の時" $ do
      it "`Nothing`を返す" $ do
        runRIO env (signup "user1" "password1")
          `shouldReturn` Nothing
      it "`createUser`を呼び出さない" $ do
        logs <- runRIO env $
          withMonitor_ $ \monitor ->
            local (userRepositoryL . createUser %~ watch monitor) $
              void $ signup "user1" "password1"
        logs `shouldSatisfy` (== 0) `times` call anything
