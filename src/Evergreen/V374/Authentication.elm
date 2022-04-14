module Evergreen.V374.Authentication exposing (..)

import Dict
import Evergreen.V374.Credentials
import Evergreen.V374.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V374.User.User
    , credentials : Evergreen.V374.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
