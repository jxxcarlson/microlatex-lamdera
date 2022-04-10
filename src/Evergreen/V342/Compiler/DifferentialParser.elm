module Evergreen.V342.Compiler.DifferentialParser exposing (..)

import Evergreen.V342.Compiler.AbstractDifferentialParser
import Evergreen.V342.Compiler.Acc
import Evergreen.V342.Parser.Block
import Evergreen.V342.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V342.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V342.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V342.Parser.Block.ExpressionBlock) Evergreen.V342.Compiler.Acc.Accumulator
