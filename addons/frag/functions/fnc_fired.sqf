#include "..\script_component.hpp"
/*
 * Author: nou, jaynus, Lambda.Tiger, PabstMirror
 * Add "Exploded" eventhandler to a projectile if it will produce fragments
 * and a "HitPart" eventhandler if it will produce spall.
 *
 * Arguments:
 * Parameters inherited from EFUNC(common,firedEH)
 *
 * Return Value:
 * Nothing Useful
 *
 * Example:
 * [clientFiredBIS-XEH] call ace_frag_fnc_fired
 *
 * Public: No
 */

//IGNORE_PRIVATE_WARNING ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle", "_gunner", "_turret"];
TRACE_10("firedEH:",_unit,_weapon,_muzzle,_mode,_ammo,_magazine,_projectile,_vehicle,_gunner,_turret);

if (_ammo isEqualTo "" || {isNull _projectile} ||
    !(if (isNil "_gunner") then {local _unit} else {local _gunner}) ||
    {_projectile getVariable [QGVAR(blacklisted), false]}) exitWith {
    TRACE_2("bad ammo or projectile, or blackList",_ammo,_projectile);
};

#ifdef DEBUG_MODE_DRAW
if (GVAR(debugOptions) && {_ammo call FUNC(shouldFrag) || {_ammo call FUNC(shouldSpall)}}) then {
    [_projectile, "red", true] call FUNC(dev_trackObj);
};
#endif

if (!GVAR(spallEnabled) || {!(_ammo call FUNC(shouldSpall))}) exitWith {
    TRACE_2("No spall",GVAR(spallEnabled),_ammo call FUNC(shouldSpall));
};

private _hitPartEventHandler = _projectile addEventHandler ["HitPart", {
    params ["_projectile", "_hitObject", "", "_posASL", "_velocity", "_instigator"];
    private _ammo = typeOf _projectile;
    /*
        * Wait a frame to see what happens to the round, may result in
        * multiple hits / slowdowns getting shunted to the first hit
    */
    [{
        private _shotParents = _this#5;

        // only let a unit make a spall once per ACE_FRAG_SPALL_UNIT_HOLDOFF
        if (CBA_missionTime < _shotParents#1 getVariable [QGVAR(nextSpallEvent), -1]) exitWith {};

        _this call FUNC(doSpall);
    }, [_hitObject, _ammo, _projectile, _posASL, _velocity, [objNull, _instigator]]] call CBA_fnc_execNextFrame;
}];
_projectile setVariable [QGVAR(hitPartEventHandler), _hitPartEventHandler];

TRACE_1("firedExit",_ammo);
