module Evergreen.V334.Compiler.DifferentialParser exposing (..)

import Evergreen.V334.Compiler.AbstractDifferentialParser
import Evergreen.V334.Compiler.Acc
import Evergreen.V334.Parser.Block
import Evergreen.V334.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V334.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V334.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V334.Parser.Block.ExpressionBlock) Evergreen.V334.Compiler.Acc.Accumulator
