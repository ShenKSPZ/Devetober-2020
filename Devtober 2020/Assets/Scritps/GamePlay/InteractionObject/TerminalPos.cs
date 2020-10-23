﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerminalPos : Interact_SO
{
    public DoorController door;

    private void Awake()
    {
        outline = GetComponent<Outline>();
        AddMenu("Operate", "Operate", true, CallNPC, 1 << LayerMask.NameToLayer("NPC"));
    }

}
