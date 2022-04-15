module Evergreen.V375.Authentication exposing (..)

import Dict
import Evergreen.V375.Credentials
import Evergreen.V375.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V375.User.User
    , credentials : Evergreen.V375.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
