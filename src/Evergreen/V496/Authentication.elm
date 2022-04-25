module Evergreen.V496.Authentication exposing (..)

import Dict
import Evergreen.V496.Credentials
import Evergreen.V496.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V496.User.User
    , credentials : Evergreen.V496.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
