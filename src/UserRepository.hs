module UserRepository where

import User (User, Username)

findByUsername :: Username -> IO (Maybe User)
findByUsername = error "To be implemented"

createUser :: User -> IO ()
createUser = error "To be implemented"