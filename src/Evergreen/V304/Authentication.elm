module Evergreen.V304.Authentication exposing (..)

import Dict
import Evergreen.V304.Credentials
import Evergreen.V304.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V304.User.User
    , credentials : Evergreen.V304.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
