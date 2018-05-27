/*
 * Author: Brandon (TCVM), PabstMirror
 * Dumps ammo to container
 *
 * Arguments:
 * 0: Weapon <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [weapon] call ace_csw_fnc_staticWeaponInit_unloadExtraMags
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_staticWeapon"];
TRACE_1("staticWeaponInit_unloadExtraMags",_staticWeapon);
if (!alive _staticWeapon) exitWith {TRACE_1("dead/deleted",alive _staticWeapon);};

private _assemblyMode = [false, true, GVAR(defaultAssemblyMode)] select (_staticWeapon getVariable [QGVAR(assemblyMode), 2]);
private _emptyWeapon = _staticWeapon getVariable [QGVAR(emptyWeapon), false];
TRACE_2("",_assemblyMode,_emptyWeapon);

if (!_assemblyMode) exitWith {};

private _desiredAmmo = getNumber (configFile >> "CfgVehicles" >> (typeOf _staticWeapon) >> QUOTE(ADDON) >> "desiredAmmo");
private _storeExtraMagazines = GVAR(handleExtraMagazines);
if (_emptyWeapon) then {
    _desiredAmmo = 0;
    _storeExtraMagazines = false;
};
TRACE_2("settings",_desiredAmmo,_storeExtraMagazines);

private _magsToRemove = [];
private _loadedMagazineInfo = [];
private _containerMagazineClassnames = [];
private _containerMagazineCount = [];

{
    _x params ["_xMag", "_xTurret", "_xAmmo"];

    private _carryMag = GVAR(vehicleMagCache) getVariable _xMag;
    if (isNil "_carryMag") then {
        private _groups = "getNumber (_x >> _xMag) == 1" configClasses (configFile >> QGVAR(groups));
        _carryMag = configName (_groups param [0, configNull]);
        GVAR(vehicleMagCache) setVariable [_xMag, _carryMag];
        TRACE_2("setting cache",_xMag,_carryMag);
    };
    if (_carryMag != "") then {
        if ((_desiredAmmo > 0) && {_loadedMagazineInfo isEqualTo []}) then {
            private _loadedMagAmmo = _desiredAmmo min _xAmmo;
            _loadedMagazineInfo = [_xMag, _xTurret, _loadedMagAmmo];
            _xAmmo = _xAmmo - _loadedMagAmmo;
            TRACE_1("",_loadedMagAmmo);
        };
        if (_xAmmo > 0) then {
            _magsToRemove pushBackUnique [_xMag, _xTurret];
            private _index = _containerMagazineClassnames find _carryMag;
            if (_index < 0) then {
                _index = _containerMagazineClassnames pushBack _carryMag;
                _containerMagazineCount pushBack 0;
            };
            _containerMagazineCount set [_index, (_containerMagazineCount select _index) + _xAmmo];
        };
    } else {
        if ((_xMag select [0,4]) != "fake") then { WARNING_1("Unable to unload [%1] - No matching carry mag",_xMag); };
    };
} forEach (magazinesAllTurrets _staticWeapon);


TRACE_1("Remove all loaded magazines",_magsToRemove);
{ _staticWeapon removeMagazinesTurret _x; } forEach _magsToRemove;

TRACE_1("Re-add the starting mag",_loadedMagazineInfo);
if (!(_loadedMagazineInfo isEqualTo [])) then {
    _staticWeapon addMagazineTurret _loadedMagazineInfo;
};

if (_storeExtraMagazines && {(count _containerMagazineClassnames) > 0}) then {
    // Create ground weapon holder container
    private _weaponRelPos = _staticWeapon getRelPos RELATIVE_DIRECTION(270);
    _weaponRelPos set [2, ((getPosATL _staticWeapon) select 2) + 0.1];
    private _container = createVehicle ["groundWeaponHolder", [0, 0, 0], [], 0, "NONE"];
    _container setPosATL _weaponRelPos;
    if ((_weaponRelPos select 2) < 0.5) then {
        _container setVectorUp (surfaceNormal _weaponRelPos);
    };
    _container setDir random [0, 180, 360];
    TRACE_2("Creating Container",_container,_weaponRelPos);

    {
        private _carryMag = _x;
        private _ammo = _containerMagazineCount select _forEachIndex;

        private _carryMaxAmmo = getNumber (configFile >> "CfgMagazines" >> _carryMag >> "count");
        private _fullMagazines = floor (_ammo / _carryMaxAmmo);
        private _bulletsRemaining = _ammo % _carryMaxAmmo;
        TRACE_5("unloading",_x,_ammo,_carryMaxAmmo,_fullMagazines,_bulletsRemaining);
        _container addMagazineAmmoCargo [_carryMag, _fullMagazines, _carryMaxAmmo];
        if (_bulletsRemaining > 0) then {
            _container addMagazineAmmoCargo [_carryMag, 1, _bulletsRemaining];
        };
    } forEach _containerMagazineClassnames;
};
