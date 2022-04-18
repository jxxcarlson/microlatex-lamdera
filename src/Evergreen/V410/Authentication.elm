module Evergreen.V410.Authentication exposing (..)

import Dict
import Evergreen.V410.Credentials
import Evergreen.V410.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V410.User.User
    , credentials : Evergreen.V410.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
