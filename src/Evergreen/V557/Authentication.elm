module Evergreen.V557.Authentication exposing (..)

import Dict
import Evergreen.V557.Credentials
import Evergreen.V557.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V557.User.User
    , credentials : Evergreen.V557.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
