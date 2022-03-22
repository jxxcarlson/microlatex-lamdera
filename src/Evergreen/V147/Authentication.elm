module Evergreen.V147.Authentication exposing (..)

import Dict
import Evergreen.V147.Credentials
import Evergreen.V147.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V147.User.User
    , credentials : Evergreen.V147.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
