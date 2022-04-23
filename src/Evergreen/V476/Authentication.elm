module Evergreen.V476.Authentication exposing (..)

import Dict
import Evergreen.V476.Credentials
import Evergreen.V476.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V476.User.User
    , credentials : Evergreen.V476.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
