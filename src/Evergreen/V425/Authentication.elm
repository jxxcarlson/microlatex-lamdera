module Evergreen.V425.Authentication exposing (..)

import Dict
import Evergreen.V425.Credentials
import Evergreen.V425.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V425.User.User
    , credentials : Evergreen.V425.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
