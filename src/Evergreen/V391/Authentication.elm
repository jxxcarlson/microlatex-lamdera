module Evergreen.V391.Authentication exposing (..)

import Dict
import Evergreen.V391.Credentials
import Evergreen.V391.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V391.User.User
    , credentials : Evergreen.V391.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
