module Evergreen.V91.Authentication exposing (..)

import Dict
import Evergreen.V91.Credentials
import Evergreen.V91.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V91.User.User
    , credentials : Evergreen.V91.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
