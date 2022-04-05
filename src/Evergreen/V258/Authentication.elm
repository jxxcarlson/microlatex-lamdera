module Evergreen.V258.Authentication exposing (..)

import Dict
import Evergreen.V258.Credentials
import Evergreen.V258.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V258.User.User
    , credentials : Evergreen.V258.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
