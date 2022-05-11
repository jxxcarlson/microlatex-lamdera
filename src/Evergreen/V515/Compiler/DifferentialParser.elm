module Evergreen.V515.Compiler.DifferentialParser exposing (..)

import Evergreen.V515.Compiler.AbstractDifferentialParser
import Evergreen.V515.Compiler.Acc
import Evergreen.V515.Parser.Block
import Evergreen.V515.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V515.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V515.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V515.Parser.Block.ExpressionBlock) Evergreen.V515.Compiler.Acc.Accumulator
