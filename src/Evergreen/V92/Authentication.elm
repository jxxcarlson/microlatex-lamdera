module Evergreen.V92.Authentication exposing (..)

import Dict
import Evergreen.V92.Credentials
import Evergreen.V92.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V92.User.User
    , credentials : Evergreen.V92.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
