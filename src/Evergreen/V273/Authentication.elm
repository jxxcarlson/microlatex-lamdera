module Evergreen.V273.Authentication exposing (..)

import Dict
import Evergreen.V273.Credentials
import Evergreen.V273.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V273.User.User
    , credentials : Evergreen.V273.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
