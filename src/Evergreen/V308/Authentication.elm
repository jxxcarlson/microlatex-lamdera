module Evergreen.V308.Authentication exposing (..)

import Dict
import Evergreen.V308.Credentials
import Evergreen.V308.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V308.User.User
    , credentials : Evergreen.V308.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
