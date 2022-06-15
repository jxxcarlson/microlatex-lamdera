module Evergreen.V631.Authentication exposing (..)

import Dict
import Evergreen.V631.Credentials
import Evergreen.V631.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V631.User.User
    , credentials : Evergreen.V631.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
