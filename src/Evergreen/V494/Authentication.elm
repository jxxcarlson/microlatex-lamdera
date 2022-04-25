module Evergreen.V494.Authentication exposing (..)

import Dict
import Evergreen.V494.Credentials
import Evergreen.V494.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V494.User.User
    , credentials : Evergreen.V494.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
