module Evergreen.V225.Authentication exposing (..)

import Dict
import Evergreen.V225.Credentials
import Evergreen.V225.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V225.User.User
    , credentials : Evergreen.V225.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
