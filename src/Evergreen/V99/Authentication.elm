module Evergreen.V99.Authentication exposing (..)

import Dict
import Evergreen.V99.Credentials
import Evergreen.V99.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V99.User.User
    , credentials : Evergreen.V99.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
