module Evergreen.V536.Authentication exposing (..)

import Dict
import Evergreen.V536.Credentials
import Evergreen.V536.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V536.User.User
    , credentials : Evergreen.V536.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
