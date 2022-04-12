module Evergreen.V360.Authentication exposing (..)

import Dict
import Evergreen.V360.Credentials
import Evergreen.V360.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V360.User.User
    , credentials : Evergreen.V360.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
