/*
 * Author: KoffeinFlummi, Commy2, Ruthberg
 * Check if weapon optics changed and reset zeroing if needed
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ace_scopes_fnc_inventoryCheck
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_player"];

private _adjustment = ACE_player getVariable [QGVAR(Adjustment), [[0, 0, 0], [0, 0, 0], [0, 0, 0]]];
private _updateAdjustment = false;

private _newOptics = [_player] call FUNC(getOptics);
private _newGuns = [primaryWeapon _player, secondaryWeapon _player, handgunWeapon _player];

{
    if (_newOptics select _forEachIndex != _x) then {
        // The optic for this weapon changed, set adjustment to zero
        if (!((_adjustment select _forEachIndex) isEqualTo [0, 0, 0])) then {
            _adjustment set [_forEachIndex, [0, 0, 0]];
            _updateAdjustment = true;
        };
        private _opticConfig = configFile >> "CfgWeapons" >> (_newOptics select _forEachIndex);        
        private _verticalIncrement = -1;
        if (isNumber (_opticConfig >> "ACE_ScopeAdjust_VerticalIncrement")) then {
            _verticalIncrement = getNumber (_opticConfig >> "ACE_ScopeAdjust_VerticalIncrement");
        };
        private _horizontalIncrement = -1;
        if (isNumber (_opticConfig >> "ACE_ScopeAdjust_HorizontalIncrement")) then {
            _horizontalIncrement = getNumber (_opticConfig >> "ACE_ScopeAdjust_HorizontalIncrement");
        };
        private _maxVertical = [];
        if (isArray (_opticConfig >> "ACE_ScopeAdjust_Vertical")) then {
            _maxVertical = getArray (_opticConfig >> "ACE_ScopeAdjust_Vertical");
        };
        private _maxHorizontal = [];
        if (isArray (_opticConfig >> "ACE_ScopeAdjust_Horizontal")) then {
            _maxHorizontal = getArray (_opticConfig >> "ACE_ScopeAdjust_Horizontal");
        };
        if (GVAR(forceUseOfAdjustmentTurrets)) then {
            if (_maxVertical   isEqualTo []) then { _maxVertical   = [-4, 30]; };
            if (_maxHorizontal isEqualTo []) then { _maxHorizontal = [-6,  6]; };
            if (_verticalIncrement   == -1) then { _verticalIncrement   = 0.1; };
            if (_horizontalIncrement == -1) then { _horizontalIncrement = 0.1; };
        } else {
            if (_maxVertical   isEqualTo []) then { _maxVertical   = [0, 0]; };
            if (_maxHorizontal isEqualTo []) then { _maxHorizontal = [0, 0]; };
            if (_verticalIncrement   == -1) then { _verticalIncrement   = 0; };
            if (_horizontalIncrement == -1) then { _horizontalIncrement = 0; };
        };
        (GVAR(scopeAdjust) select _forEachIndex) set [0, _maxVertical];
        (GVAR(scopeAdjust) select _forEachIndex) set [1, _verticalIncrement];
        (GVAR(scopeAdjust) select _forEachIndex) set [2, _maxHorizontal];
        (GVAR(scopeAdjust) select _forEachIndex) set [3, _horizontalIncrement];
        GVAR(canAdjustElevation) set [_forEachIndex, (_verticalIncrement > 0) && !(_maxVertical isEqualTo [0, 0])];
        GVAR(canAdjustWindage) set [_forEachIndex, (_horizontalIncrement > 0) && !(_maxHorizontal isEqualTo [0, 0])];
    };
} forEach GVAR(Optics);

{
    if ((_newOptics select _x) != (GVAR(Optics) select _x) || (_newGuns select _x != GVAR(Guns) select _x)) then {
        // Determine rail height above bore
        private _railHeightAboveBore = 0;
        private _weaponConfig = configFile >> "CfgWeapons" >> (_newGuns select _x);
        if (isNumber (_weaponConfig >> "ACE_RailHeightAboveBore")) then {
            _railHeightAboveBore = getNumber(_weaponConfig >> "ACE_RailHeightAboveBore");
        } else {
            switch (_x) do {
                case 0: { _railHeightAboveBore = 2.0; }; // Rifle
                case 2: { _railHeightAboveBore = 0.7; }; // Pistol
            };
        };
        // Determine scope height above rail
        private _scopeHeightAboveRail = 0;
        private _opticConfig = configFile >> "CfgWeapons" >> (_newOptics select _x);
        if (isNumber (_opticConfig >> "ACE_ScopeHeightAboveRail")) then {
            _scopeHeightAboveRail = getNumber(_opticConfig >> "ACE_ScopeHeightAboveRail");
        } else {
            switch (getNumber(_opticConfig >> "ItemInfo" >> "opticType")) do {
                case 1: { _scopeHeightAboveRail = 3.0; }; // RCO or similar
                case 2: { _scopeHeightAboveRail = 4.0; }; // High power scope
                default {
                    switch (_x) do {
                        case 0: { _scopeHeightAboveRail = 0.5; }; // Rifle iron sights
                        case 2: { _scopeHeightAboveRail = 0.3; }; // Pistol iron sights
                    };
                };
            };
        };
        GVAR(boreHeight) set [_x, _railHeightAboveBore + _scopeHeightAboveRail];
                
        if ((_newOptics select _x) == "") then {
            // Check if the weapon comes with an integrated optic     
            private _verticalIncrement = 0;
            if (isNumber (_weaponConfig >> "ACE_ScopeAdjust_VerticalIncrement")) then {
                _verticalIncrement = getNumber (_weaponConfig >> "ACE_ScopeAdjust_VerticalIncrement");
            };
            private _horizontalIncrement = 0;
            if (isNumber (_weaponConfig >> "ACE_ScopeAdjust_HorizontalIncrement")) then {
                _horizontalIncrement = getNumber (_weaponConfig >> "ACE_ScopeAdjust_HorizontalIncrement");
            };
            private _maxVertical = [0, 0];
            if (isArray (_weaponConfig >> "ACE_ScopeAdjust_Vertical")) then {
                _maxVertical = getArray (_weaponConfig >> "ACE_ScopeAdjust_Vertical");
            };
            private _maxHorizontal = [0, 0];
            if (isArray (_weaponConfig >> "ACE_ScopeAdjust_Horizontal")) then {
                _maxHorizontal = getArray (_weaponConfig >> "ACE_ScopeAdjust_Horizontal");
            };
            (GVAR(scopeAdjust) select _x) set [0, _maxVertical];
            (GVAR(scopeAdjust) select _x) set [1, _verticalIncrement];
            (GVAR(scopeAdjust) select _x) set [2, _maxHorizontal];
            (GVAR(scopeAdjust) select _x) set [3, _horizontalIncrement];
            GVAR(canAdjustElevation) set [_x, (_verticalIncrement > 0) && !(_maxVertical isEqualTo [0, 0])];
            GVAR(canAdjustWindage) set [_x, (_horizontalIncrement > 0) && !(_maxHorizontal isEqualTo [0, 0])];
        };
    }
} forEach [0, 1, 2];

if (_updateAdjustment) then {
    [ACE_player, QGVAR(Adjustment), _adjustment, 0.5] call EFUNC(common,setVariablePublic);
};

GVAR(Optics) = _newOptics;
GVAR(Guns) = _newGuns;
