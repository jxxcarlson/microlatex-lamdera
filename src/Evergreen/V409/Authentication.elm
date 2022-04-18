module Evergreen.V409.Authentication exposing (..)

import Dict
import Evergreen.V409.Credentials
import Evergreen.V409.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V409.User.User
    , credentials : Evergreen.V409.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
