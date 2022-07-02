module Evergreen.V684.Authentication exposing (..)

import Dict
import Evergreen.V684.Credentials
import Evergreen.V684.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V684.User.User
    , credentials : Evergreen.V684.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
