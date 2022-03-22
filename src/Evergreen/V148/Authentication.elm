module Evergreen.V148.Authentication exposing (..)

import Dict
import Evergreen.V148.Credentials
import Evergreen.V148.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V148.User.User
    , credentials : Evergreen.V148.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
