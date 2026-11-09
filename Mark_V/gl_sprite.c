#ifdef GLQUAKE // GLQUAKE specific

/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2002-2009 John Fitzgibbons and others
Copyright (C) 2007-2008 Kristian Duske
Copyright (C) 2009-2014 Baker and others

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
//r_sprite.c -- sprite model rendering

#include "quakedef.h"


/*
================
R_GetSpriteFrame
================
*/
// Baker: This function is 100% in gl and winquake
static mspriteframe_t *R_GetSpriteFrame (entity_t *currentent)
{
	msprite_t		*psprite;
	mspritegroup_t	*pspritegroup;
	mspriteframe_t	*pspriteframe;
	int				i, numframes, frame;
	float			*pintervals, fullinterval, targettime, time;

	psprite = (msprite_t *)currentent->model->cache.data;
	frame = currentent->frame;

	if ((frame >= psprite->numframes) || (frame < 0))
	{
		Con_PrintLinef ("R_DrawSprite: no such frame %d", frame);
		frame = 0;
	}

	if (psprite->frames[frame].type == SPR_SINGLE)
	{
		pspriteframe = psprite->frames[frame].frameptr;
	}
	else
	{
		pspritegroup = (mspritegroup_t *)psprite->frames[frame].frameptr;
		pintervals = pspritegroup->intervals;
		numframes = pspritegroup->numframes;
		fullinterval = pintervals[numframes-1];

		time = cl.ctime + currentent->syncbase;

	// when loading in Mod_LoadSpriteGroup, we guaranteed all interval values
	// are positive, so we don't have to worry about division by 0
		targettime = time - ((int)(time / fullinterval)) * fullinterval;

		for (i=0 ; i<(numframes-1) ; i++)
		{
			if (pintervals[i] > targettime)
				break;
		}

		pspriteframe = pspritegroup->frames[i];
	}

	return pspriteframe;
}


/*
=================
R_DrawSpriteModel
 -- johnfitz -- rewritten: now supports all orientations
=================
*/
// QuadEXQ: one sprite quad (as R_DrawSpriteModel draws it), scaled
static void R_DrawSprite_QXQuad (entity_t *e, mspriteframe_t *sp_frame, float *s_up, float *s_right, float scale)
{
	vec3_t point;

	eglBegin (GL_TRIANGLE_FAN);

	eglTexCoord2f (0, sp_frame->tmax);
	VectorMA (e->origin, sp_frame->down * scale, s_up, point);
	VectorMA (point, sp_frame->left * scale, s_right, point);
	eglVertex3fv (point);

	eglTexCoord2f (0, 0);
	VectorMA (e->origin, sp_frame->up * scale, s_up, point);
	VectorMA (point, sp_frame->left * scale, s_right, point);
	eglVertex3fv (point);

	eglTexCoord2f (sp_frame->smax, 0);
	VectorMA (e->origin, sp_frame->up * scale, s_up, point);
	VectorMA (point, sp_frame->right * scale, s_right, point);
	eglVertex3fv (point);

	eglTexCoord2f (sp_frame->smax, sp_frame->tmax);
	VectorMA (e->origin, sp_frame->down * scale, s_up, point);
	VectorMA (point, sp_frame->right * scale, s_right, point);
	eglVertex3fv (point);

	eglEnd ();
}

// QuadEXQ: QX_COLORMAP_GREEN -- tinted green, a soft green halo, a white-hot core
static void R_DrawSprite_QXGreen (entity_t *e, mspriteframe_t *sp_frame, float *s_up, float *s_right)
{
	eglTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

	eglEnable (GL_ALPHA_TEST);
	eglColor3f (0.30f, 1.0f, 0.35f);
	R_DrawSprite_QXQuad (e, sp_frame, s_up, s_right, 1.0f);
	eglDisable (GL_ALPHA_TEST);

	eglDepthMask (GL_FALSE);
	eglEnable (GL_BLEND);
	eglBlendFunc (GL_SRC_ALPHA, GL_ONE);	// (by alpha: the clear texels around the ball add nothing -- GL_ONE drew a square)
	Fog_StartAdditive ();
	eglColor3f (0.05f, 0.30f, 0.08f);			// halo
	R_DrawSprite_QXQuad (e, sp_frame, s_up, s_right, 1.6f);
	eglColor3f (0.35f, 0.40f, 0.35f);			// core
	R_DrawSprite_QXQuad (e, sp_frame, s_up, s_right, 0.6f);
	Fog_StopAdditive ();
	eglBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	eglDisable (GL_BLEND);
	eglDepthMask (GL_TRUE);

	eglColor3f (1, 1, 1);
	eglTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
}

void R_DrawSpriteModel (entity_t *e)
{
	vec3_t			point, v_forward, v_right, v_up;
	msprite_t		*psprite;
	mspriteframe_t	*sp_frame;
	float			*s_up, *s_right;
	float			angle, sr, cr;

#ifdef GLQUAKE_SUPPORTS_QMB
	if (frame.qmb && e->modelindex == cl_modelindex[mi_bubble] && qmb_bubbles.value) {
		if (cl.ctime - cl.oldtime) /*reverse time ok */ {
			QMB_StaticBubble (e, e->origin); // Draw QMB bubble instead.
		}
		return; // Now get out!
	}
#endif // GLQUAKE_SUPPORTS_QMB


	//TODO: frustum cull it?
	sp_frame = R_GetSpriteFrame (e);
	psprite = (msprite_t *)e->model->cache.data;

	switch(psprite->type)
	{
	case SPR_VP_PARALLEL_UPRIGHT: //faces view plane, up is towards the heavens
		v_up[0] = 0;
		v_up[1] = 0;
		v_up[2] = 1;
		s_up = v_up;
		s_right = vright;
		break;
	case SPR_FACING_UPRIGHT: //faces camera origin, up is towards the heavens
		VectorSubtract(e->origin, r_origin, v_forward);
		v_forward[2] = 0;
		VectorNormalizeFast(v_forward);
		v_right[0] = v_forward[1];
		v_right[1] = -v_forward[0];
		v_right[2] = 0;
		v_up[0] = 0;
		v_up[1] = 0;
		v_up[2] = 1;
		s_up = v_up;
		s_right = v_right;
		break;
	case SPR_VP_PARALLEL: //faces view plane, up is towards the top of the screen
		s_up = vup;
		s_right = vright;
		break;
	case SPR_ORIENTED: //pitch yaw roll are independent of camera
		AngleVectors (e->angles, v_forward, v_right, v_up);
		s_up = v_up;
		s_right = v_right;
		break;
	case SPR_VP_PARALLEL_ORIENTED: //faces view plane, but obeys roll value
		angle = e->angles[ROLL] * M_PI_DIV_180;
		sr = sin(angle);
		cr = cos(angle);
		v_right[0] = vright[0] * cr + vup[0] * sr;
		v_right[1] = vright[1] * cr + vup[1] * sr;
		v_right[2] = vright[2] * cr + vup[2] * sr;
		v_up[0] = vright[0] * -sr + vup[0] * cr;
		v_up[1] = vright[1] * -sr + vup[1] * cr;
		v_up[2] = vright[2] * -sr + vup[2] * cr;
		s_up = v_up;
		s_right = v_right;
		break;
	default:
		return;
	}

	//johnfitz: offset decals
#ifndef DIRECT3D9_WRAPPER // Per mh as workaround for hipnotic decals rendering through walls April 25 2018
	if (psprite->type == SPR_ORIENTED)
		GL_PolygonOffset (OFFSET_DECAL);
#endif // Per mh as workaround for hipnotic decals rendering through walls April 25 2018

	eglColor3f (1,1,1);

	GL_DisableMultitexture();

    GL_Bind(sp_frame->gltexture);

	if (e->colormap == QX_COLORMAP_GREEN)
	{	// QuadEXQ: the BFG ball -- a grey sprite drawn glowing green (the
		// Quake palette has no real green): tinted, then its light added on top
		R_DrawSprite_QXGreen (e, sp_frame, s_up, s_right);
		goto qx_done;
	}

	eglEnable (GL_ALPHA_TEST);
	eglBegin (GL_TRIANGLE_FAN); //was GL_QUADS, but changed to support r_showtris

	eglTexCoord2f (0, sp_frame->tmax);
	VectorMA (e->origin, sp_frame->down, s_up, point);
	VectorMA (point, sp_frame->left, s_right, point);
	eglVertex3fv (point);

	eglTexCoord2f (0, 0);
	VectorMA (e->origin, sp_frame->up, s_up, point);
	VectorMA (point, sp_frame->left, s_right, point);
	eglVertex3fv (point);

	eglTexCoord2f (sp_frame->smax, 0);
	VectorMA (e->origin, sp_frame->up, s_up, point);
	VectorMA (point, sp_frame->right, s_right, point);
	eglVertex3fv (point);

	eglTexCoord2f (sp_frame->smax, sp_frame->tmax);
	VectorMA (e->origin, sp_frame->down, s_up, point);
	VectorMA (point, sp_frame->right, s_right, point);
	eglVertex3fv (point);

	eglEnd ();
	eglDisable (GL_ALPHA_TEST);

qx_done:
	//johnfitz: offset decals
#ifndef DIRECT3D9_WRAPPER // Per mh as workaround for hipnotic decals rendering through walls April 25 2018
	if (psprite->type == SPR_ORIENTED)
		GL_PolygonOffset (OFFSET_NONE);
#endif // Per mh as workaround for hipnotic decals rendering through walls April 25 2018
}

#endif // GLQUAKE specific