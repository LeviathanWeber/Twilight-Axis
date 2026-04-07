import { type ReactNode, useEffect, useMemo, useRef, useState } from 'react';
import { Box, Button, DmIcon, Dropdown, Input, Section, Stack, Tabs } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type IdentityData = {
  real_name: string;
  nickname: string;
  pronouns: string;
  titles: string;
  clothes: string;
  voice_type: string;
  voice_pack: string;
  accent?: string;
  voice_color?: string;
  voice_pitch?: string | number;
  voice_pitch_min?: number;
  voice_pitch_max?: number;
  highlight_color?: string;
  dnr_pref?: boolean;
  combat_music?: string;
  domhand?: string;
};

type AppearanceData = {
  species: string;
  subspecies: string;
  origin: string;
  statpack: string;
  faith: string;
  patron: string;
  extra_language: string;
  gender_label: string;
  body_is_feminine?: boolean;
  age: string | number;
  hair_color: string;
  eye_color: string;
  skin_tone?: string;
  body_size?: string | number;
  body_size_min?: number;
  body_size_max?: number;
  taur_type: string;
  taur_color: string;
  taur_available?: boolean;
  statpack_virtuous?: boolean;
  race_bonus: string;
};

type VirtuesData = {
  virtue: string;
  virtue_two: string;
  vices: string[];
};

type RoleplayData = {
  flavortext: string;
  ooc_notes: string;
  rumour: string;
  noble_gossip: string;
  headshot_link: string;
  lich_headshot_link: string;
  vampire_headshot_link: string;
  nsfwflavortext: string;
  erpprefs: string;
  descriptor_count?: number;
  culinary_count?: number;
  sfw_gallery_count?: number;
  nsfw_gallery_count?: number;
  music_url?: string;
  song_artist?: string;
  song_title?: string;
  sfw_gallery?: string[];
  nsfw_gallery?: string[];
};

type BodyMarkingSummary = {
  zone: string;
  label: string;
  count: number;
  names: string[];
};

type BodyMarkingOption = {
  name: string;
  preview_asset?: string | null;
};

type BodyMarkingCatalog = {
  zone: string;
  label: string;
  options: BodyMarkingOption[];
};

type SlotSummary = {
  index: number;
  name: string;
  current: boolean;
  empty: boolean;
};

type JobEntry = {
  id: string;
  name: string;
  current_pref: 'never' | 'low' | 'medium' | 'high' | string;
  current_pref_label: string;
  disabled_reason?: string | null;
  tutorial?: string;
  slots?: number;
  assigned_slot?: string;
  column?: number;
  group?: string;
  separator_before?: boolean;
};

type JobSlotChoice = {
  id: string;
  label: string;
  current: boolean;
};

type CustomizerSummary = {
  id: string;
  name: string;
  disabled: boolean;
  choice_name: string;
  option_count: number;
  current_accessory_name: string;
  preview_asset?: string | null;
  icon?: string | null;
  icon_state?: string | null;
  group?: 'body' | 'simple' | string;
};

type HairCustomizer = {
  id: string;
  name: string;
  current_accessory_name: string;
  choice_name: string;
  hair_color?: string;
  natural_gradient?: string;
  natural_color?: string;
  dye_gradient?: string;
  dye_color?: string;
} | null;

type ChoiceGroup = {
  id: string;
  name: string;
  current: boolean;
};

type CustomizerOption = {
  id: string;
  name: string;
  icon?: string | null;
  icon_state?: string | null;
  preview_asset?: string | null;
  preview_assets_by_dir?: Record<string, string | null>;
};

type ActiveCustomizer = {
  id: string;
  name: string;
  disabled: boolean;
  allows_disabling: boolean;
  can_change_choice: boolean;
  choice_name: string;
  choice_groups?: ChoiceGroup[];
  current_accessory_name: string;
  selected_accessory_id?: string | null;
  option_count: number;
  total_filtered: number;
  window_start?: number;
  window_size?: number;
  search_query?: string;
  options: CustomizerOption[];
  allows_accessory_color_customization?: boolean;
  accessory_color_labels?: string[];
  accessory_color_values?: string[];
  group?: 'body' | 'simple' | string;
  is_hair?: boolean;
  head_base_assets_by_dir?: Record<string, string | null>;
  overlay_offset_y?: number;
  hair_color?: string;
  natural_gradient?: string;
  natural_color?: string;
  dye_gradient?: string;
  dye_color?: string;
};

type SimpleCustomizer = {
  id: string;
  name: string;
  disabled: boolean;
  allows_disabling: boolean;
  can_change_choice: boolean;
  choice_name: string;
  choice_groups?: ChoiceGroup[];
  current_accessory_name: string;
  selected_accessory_id?: string | null;
  option_count: number;
  options: CustomizerOption[];
  allows_accessory_color_customization?: boolean;
  accessory_color_labels?: string[];
  accessory_color_values?: string[];
  size_label?: string;
  size_value?: string | number | null;
  size_var_name?: string | null;
  size_is_numeric?: boolean;
  size_options?: SelectionOption[];
  size_selected_id?: string | null;
};

type AntagRole = {
  id: string;
  name: string;
  enabled: boolean;
  disabled_reason?: string | null;
};

type VillainSettings = {
  lich_headshot_link?: string | null;
  vampire_headshot_link?: string | null;
  qsr_pref?: boolean;
  vampire_skin?: string | null;
  vampire_eyes?: string | null;
  vampire_hair?: string | null;
  vampire_ears?: string | null;
};

type SystemSettings = {
  tgui_theme?: string | null;
  tgui_theme_name?: string | null;
  tgui_lock?: boolean;
  ambientocclusion?: boolean;
  windowflashing?: boolean;
  clientfps?: number;
  auto_fit_viewport?: boolean;
  widescreenpref?: boolean;
  chat_on_map?: boolean;
  see_chat_non_mob?: boolean;
  buttons_locked?: boolean;
  anonymize?: boolean;
  masked_examine?: boolean;
  full_examine?: boolean;
  mute_animal_emotes?: boolean;
  autoconsume?: boolean;
  no_examine_blocks?: boolean;
  no_autopunctuate?: boolean;
  no_language_fonts?: boolean;
  no_language_icon?: boolean;
  no_redflash?: boolean;
  is_admin?: boolean;
  play_admin_midis?: boolean;
  hear_adminhelps?: boolean;
  asaycolor?: string | null;
  can_edit_asaycolor?: boolean;
  deadmin_always?: boolean;
  deadmin_antag?: boolean;
  deadmin_head?: boolean;
  schizo_voice?: boolean;
  examine_theme_name?: string;
  deadmin_always_forced?: boolean;
  deadmin_antag_forced?: boolean;
  deadmin_head_forced?: boolean;
};

type KeybindEntry = {
  id: string;
  label: string;
  keys: string[];
};

type KeybindCategory = {
  name: string;
  bindings: KeybindEntry[];
};

type SelectionOption = {
  id: string;
  name: string;
  description?: string;
  meta?: string;
  current?: boolean;
  group?: string;
  icon?: string | null;
  icon_state?: string | null;
  preview_asset?: string | null;
};

type ContextSelector = {
  title: string;
  current?: string;
  options: SelectionOption[];
};

type ViceOption = {
  id: string;
  name: string;
  description?: string;
  selected?: boolean;
};

type DescriptorChoiceEntry = {
  id: string;
  name: string;
  value: string;
  options: SelectionOption[];
};

type CustomDescriptorEntry = {
  index: number;
  visible: boolean;
  prefix_id: string;
  prefix_label: string;
  content: string;
  prefix_options: SelectionOption[];
};

type DescriptorEditorData = {
  entries: DescriptorChoiceEntry[];
  custom_entries: CustomDescriptorEntry[];
};

type CulinaryChoice = {
  key: string;
  label: string;
  value: string;
  mode: 'food' | 'drink';
  options: SelectionOption[];
};

type CulinaryEditorData = {
  entries: CulinaryChoice[];
};

type FamiliarEditorData = {
  familiar_name: string;
  familiar_pronouns: string;
  familiar_pronoun_id: string;
  familiar_headshot_link: string;
  familiar_flavortext: string;
  familiar_ooc_notes: string;
  familiar_ooc_extra_link: string;
  familiar_specie: string;
  familiar_specie_id: string;
  queue_joined?: boolean;
  lore_blurb?: string;
  pronoun_options: SelectionOption[];
  species_options: SelectionOption[];
};

type Data = {
  loaded_slot: number;
  max_save_slots: number;
  slot_summaries: SlotSummary[];
  player_quality: string;
  triumphs?: string | number | null;
  loadout_count: number;
  preview_asset?: string | null;
  preview_token?: number;
  species_warning?: string | null;
  identity: IdentityData;
  appearance: AppearanceData;
  virtues: VirtuesData;
  roleplay: RoleplayData;
  body_markings: BodyMarkingSummary[];
  body_marking_catalog?: BodyMarkingCatalog[];
  customizer_summaries: CustomizerSummary[];
  genital_customizers: SimpleCustomizer[];
  body_context_customizers?: SimpleCustomizer[];
  hair_customizer: HairCustomizer;
  facial_hair_customizer?: HairCustomizer;
  active_customizer?: ActiveCustomizer | null;
  job_entries: JobEntry[];
  job_slot_target?: string | null;
  job_slot_choices?: JobSlotChoice[];
  current_joblessrole?: string;
  preview_direction?: string;
  antag_roles?: AntagRole[];
  villain_settings?: VillainSettings;
  system_settings?: SystemSettings;
  keybind_mode?: string;
  keybinding_categories?: KeybindCategory[];
  voice_type_choices?: string[];
  context_selectors?: Record<string, ContextSelector>;
  vice_options?: ViceOption[];
  vice_limit?: number;
  descriptor_editor?: DescriptorEditorData;
  culinary_editor?: CulinaryEditorData;
  familiar_editor?: FamiliarEditorData;
};

type MainTab = 'general' | 'appearance' | 'markings' | 'notes' | 'antags' | 'system' | 'keys';
type DialogTab = 'slots' | 'jobs' | 'job_slot' | 'feature' | 'gender' | 'vices' | 'descriptors' | 'culinary' | 'familiar' | 'combat_music' | null;


const cardStyle = {
  border: '1px solid rgba(255,255,255,0.12)',
};

const selectedCardStyle = {
  border: '1px solid rgba(255,255,255,0.32)',
  boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.08)',
};

const modalBackdrop = {
  position: 'absolute' as const,
  inset: '0',
  background: 'rgba(0, 0, 0, 0.82)',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  zIndex: 30,
};

const normalizeCssColor = (color?: string | null) => {
  if (!color) {
    return null;
  }
  if (color.startsWith('#') || color.startsWith('rgb') || color.startsWith('hsl')) {
    return color;
  }
  if (/^[0-9a-f]{3,8}$/i.test(color)) {
    return `#${color}`;
  }
  return color;
};

const swatch = (color?: string | null) => {
  const cssColor = normalizeCssColor(color);
  if (!cssColor) {
    return null;
  }
  return (
    <Box
      inline
      ml={0.5}
      style={{
        width: '12px',
        height: '12px',
        backgroundColor: cssColor,
        border: '1px solid rgba(255,255,255,0.25)',
        verticalAlign: 'middle',
      }}
    />
  );
};

const truncate = (value?: string | null, max = 180) => {
  if (!value) {
    return 'Не задано';
  }
  return value.length > max ? `${value.slice(0, max)}…` : value;
};

const translateChoiceValue = (value?: string | null) => {
  if (!value) {
    return 'Не задано';
  }
  const raw = `${value}`;
  const lower = raw.toLowerCase();

  if (lower === 'androgynous') {
    return 'Андрогинный';
  }
  if (lower === 'masculine') {
    return 'Мужской';
  }
  if (lower === 'feminine') {
    return 'Женский';
  }
  if (lower === 'he/him') {
    return 'he/him';
  }
  if (lower === 'she/her') {
    return 'she/her';
  }
  if (lower === 'they/them') {
    return 'they/them';
  }
  if (lower === 'it/its') {
    return 'it/its';
  }

  return raw;
};



const PixelPreview = (props: {
  asset?: string | null;
  token?: number;
  alt: string;
  width: string;
  height: string;
  fallback?: ReactNode;
}) => {
  const [broken, setBroken] = useState(false);
  useEffect(() => setBroken(false), [props.asset, props.token]);

  if (!props.asset || broken) {
    return props.fallback !== undefined ? props.fallback : <Box color="label">Нет</Box>;
  }

  return (
    <img
      key={`${props.asset || 'none'}|${props.token || 0}`}
      alt={props.alt}
      src={props.asset || undefined}
      onError={() => setBroken(true)}
      style={{
        width: props.width,
        height: props.height,
        objectFit: 'contain',
        imageRendering: 'pixelated',
      }}
    />
  );
};

const ModalShell = (props: {
  title: string;
  width?: string;
  children: ReactNode;
  onClose: () => void;
}) => (
  <Box style={modalBackdrop}>
    <Box
      style={{
        width: props.width || '1180px',
        maxWidth: '96%',
        maxHeight: '92%',
        overflow: 'hidden',
        border: '1px solid rgba(255,255,255,0.14)',
        background: 'rgba(0,0,0,0.96)',
      }}
    >
      <Box
        px={1}
        py={0.75}
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid rgba(255,255,255,0.12)',
        }}
      >
        <Box bold>{props.title}</Box>
        <Button onClick={props.onClose}>Закрыть</Button>
      </Box>
      <Box p={1} style={{ maxHeight: '84vh', overflow: 'auto' }}>
        {props.children}
      </Box>
    </Box>
  </Box>
);

const CompactRow = (props: {
  label: string;
  value: ReactNode;
  onClick?: () => void;
  colorPreview?: string | null;
  subtle?: boolean;
  wrap?: boolean;
  auxButton?: ReactNode;
  labelBasis?: string;
}) => {
  const valueNode = (
    <Box
      bold
      style={props.wrap ? { overflowWrap: 'anywhere', whiteSpace: 'normal', lineHeight: 1.15, wordBreak: 'break-word' } : { overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
    >
      {props.value}
      {swatch(props.colorPreview)}
    </Box>
  );

  return (
    <Box mb={0.35} p={0.35} style={{ ...cardStyle, opacity: props.subtle ? 0.88 : 1 }}>
      <Stack align={props.wrap ? 'start' : 'center'}>
        <Stack.Item basis={props.labelBasis || '180px'} shrink={0}>
          <Box color="label">{props.label}</Box>
        </Stack.Item>
        {props.auxButton ? (
          <Stack.Item shrink={0} mr={0.35}>
            {props.auxButton}
          </Stack.Item>
        ) : null}
        <Stack.Item grow>
          {props.onClick ? (
            <Button fluid textAlign="left" onClick={props.onClick} style={{ minHeight: props.wrap ? 'unset' : '28px' }}>
              {valueNode}
            </Button>
          ) : (
            <Box px={0.7} py={0.45} style={cardStyle}>
              {valueNode}
            </Box>
          )}
        </Stack.Item>
      </Stack>
    </Box>
  );
};


const getPrimaryCustomizerColor = (entry?: SimpleCustomizer | null) => entry?.accessory_color_values?.[0] || null;

const PaletteButton = (props: {
  color?: string | null;
  disabled?: boolean;
  onClick: () => void;
}) => (
  <Button
    compact
    icon="palette"
    disabled={props.disabled}
    onClick={props.onClick}
    style={{
      minWidth: '28px',
      width: '28px',
      height: '28px',
      padding: 0,
      border: props.color ? `1px solid ${props.color}` : undefined,
      boxShadow: props.color ? `inset 0 0 0 1px ${props.color}` : undefined,
    }}
  />
);

const clampNumericValue = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const normalizeStepValue = (value: number, step: number) => {
  if (step >= 1) {
    return Math.round(value);
  }
  const decimals = Math.max(0, (`${step}`.split('.')[1] || '').length);
  return Number(value.toFixed(decimals));
};

const SliderNumberRow = (props: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onCommit: (value: number) => void;
  paletteColor?: string | null;
  onPaletteClick?: () => void;
  disabled?: boolean;
  labelBasis?: string;
}) => {
  const [draft, setDraft] = useState(String(props.value));

  useEffect(() => {
    setDraft(String(props.value));
  }, [props.value]);

  const commitValue = (rawValue: number) => {
    if (!Number.isFinite(rawValue)) {
      setDraft(String(props.value));
      return;
    }
    const nextValue = normalizeStepValue(clampNumericValue(rawValue, props.min, props.max), props.step);
    setDraft(String(nextValue));
    if (nextValue !== props.value) {
      props.onCommit(nextValue);
    }
  };

  return (
    <Box mb={0.35} p={0.35} style={cardStyle}>
      <Stack align="center">
        <Stack.Item basis={props.labelBasis || '180px'} shrink={0}>
          <Box color="label">{props.label}</Box>
        </Stack.Item>
        {props.onPaletteClick ? (
          <Stack.Item shrink={0} mr={0.35}>
            <PaletteButton
              color={props.paletteColor}
              disabled={props.disabled}
              onClick={props.onPaletteClick}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item grow>
          <input
            type="range"
            min={props.min}
            max={props.max}
            step={props.step}
            disabled={props.disabled}
            value={draft}
            onChange={(event) => setDraft(event.currentTarget.value)}
            onMouseUp={(event) => commitValue(Number(event.currentTarget.value))}
            onTouchEnd={(event) => commitValue(Number((event.currentTarget as HTMLInputElement).value))}
            style={{ width: '100%' }}
          />
        </Stack.Item>
        <Stack.Item basis="78px" shrink={0}>
          <input
            type="number"
            min={props.min}
            max={props.max}
            step={props.step}
            disabled={props.disabled}
            value={draft}
            onChange={(event) => setDraft(event.currentTarget.value)}
            onBlur={(event) => commitValue(Number(event.currentTarget.value))}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                commitValue(Number((event.currentTarget as HTMLInputElement).value));
              }
            }}
            style={{ width: '100%' }}
          />
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const FeatureButton = (props: {
  label: string;
  selected?: boolean;
  previewAsset?: string | null;
  previewToken?: number;
  icon?: string | null;
  iconState?: string | null;
  onClick: () => void;
}) => (
  <Button
    selected={props.selected}
    tooltip={props.label}
    tooltipPosition="right"
    onClick={props.onClick}
    style={{
      width: '54px',
      height: '54px',
      padding: '3px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'rgba(255,255,255,0.04)',
    }}
  >
    <Box
      style={{
        width: '44px',
        height: '44px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(255,255,255,0.07)',
      }}
    >
      <PixelPreview
        asset={props.previewAsset}
        token={props.previewToken}
        alt={props.label}
        width="40px"
        height="40px"
        fallback={props.icon ? (
          <DmIcon icon={props.icon} icon_state={props.iconState || ''} width="40px" height="40px" />
        ) : (
          <Box fontSize={0.65}>{props.label.slice(0, 2)}</Box>
        )}
      />
    </Box>
  </Button>
);

const SlotModal = (props: {
  slots: SlotSummary[];
  onSelect: (slot: number) => void;
  onClose: () => void;
}) => {
  const [search, setSearch] = useState('');
  const filtered = useMemo(
    () => props.slots.filter((slot) => `${slot.index} ${slot.name}`.toLowerCase().includes(search.toLowerCase())),
    [props.slots, search],
  );

  return (
    <ModalShell title="Смена персонажа" width="760px" onClose={props.onClose}>
      <Input
        fluid
        mb={1}
        placeholder="Поиск по имени или номеру слота..."
        value={search}
        onChange={setSearch}
      />
      <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '10px' }}>
        {filtered.map((slot) => (
          <Box key={slot.index} p={0.75} style={slot.current ? selectedCardStyle : cardStyle}>
            <Box bold mb={0.25}>Слот {slot.index}</Box>
            <Box mb={0.25}>{slot.name}</Box>
            {(slot.current || slot.empty) ? (
              <Box color="label" mb={0.5}>
                {slot.current ? 'Текущий слот' : 'Пустой слот'}
              </Box>
            ) : <Box mb={0.5} />}
            <Button fluid disabled={slot.current} onClick={() => props.onSelect(slot.index)}>
              {slot.current ? 'Выбран' : 'Открыть'}
            </Button>
          </Box>
        ))}
      </Box>
    </ModalShell>
  );
};


const previewDirectionOrder = ['SOUTH', 'WEST', 'NORTH', 'EAST'];

const OptionTile = (props: {
  option: CustomizerOption;
  customizerId?: string;
  selected: boolean;
  showImage: boolean;
  token?: number;
  rotatable?: boolean;
  headBaseAssetsByDir?: Record<string, string | null>;
  overlayOffsetY?: number;
  onClick: () => void;
}) => {
  const { act } = useBackend<Data>();
  const [directionIndex, setDirectionIndex] = useState(0);
  const [requestedDirections, setRequestedDirections] = useState<Record<string, boolean>>({});

  useEffect(() => {
    setDirectionIndex(0);
    setRequestedDirections({});
  }, [props.option.id, props.option.preview_asset]);

  const previewAssetsByDir = props.option.preview_assets_by_dir;
  const headBaseAssetsByDir = props.headBaseAssetsByDir;
  const currentDirection = previewDirectionOrder[((directionIndex % previewDirectionOrder.length) + previewDirectionOrder.length) % previewDirectionOrder.length];
  const currentAsset = previewAssetsByDir?.[currentDirection] || props.option.preview_asset;
  const currentBaseAsset = headBaseAssetsByDir?.[currentDirection] || headBaseAssetsByDir?.SOUTH || null;
  const canRotate = !!props.rotatable && (!!previewAssetsByDir || !!headBaseAssetsByDir)
    && previewDirectionOrder.some((dir) => !!previewAssetsByDir?.[dir] || !!headBaseAssetsByDir?.[dir]);

  useEffect(() => {
    if (!previewAssetsByDir && !headBaseAssetsByDir) {
      return;
    }
    setRequestedDirections((previous) => {
      let changed = false;
      const next = { ...previous };
      previewDirectionOrder.forEach((dir) => {
        if ((previewAssetsByDir?.[dir] || headBaseAssetsByDir?.[dir]) && next[dir]) {
          delete next[dir];
          changed = true;
        }
      });
      return changed ? next : previous;
    });
  }, [previewAssetsByDir, headBaseAssetsByDir]);

  const rotatePreview = (step: number) => {
    const nextIndex = directionIndex + step;
    const nextDirection = previewDirectionOrder[((nextIndex % previewDirectionOrder.length) + previewDirectionOrder.length) % previewDirectionOrder.length];
    const missingOverlay = !previewAssetsByDir?.[nextDirection];
    const missingBase = !!headBaseAssetsByDir && !headBaseAssetsByDir[nextDirection];
    if (props.customizerId && (missingOverlay || missingBase) && !requestedDirections[nextDirection]) {
      setRequestedDirections((previous) => ({ ...previous, [nextDirection]: true }));
      act('load_customizer_option_preview_dir', {
        customizer: props.customizerId,
        accessory: props.option.id,
        direction: nextDirection,
      });
    }
    setDirectionIndex(nextIndex);
  };

  return (
    <Box
      p={0.45}
      style={{
        ...(props.selected ? selectedCardStyle : cardStyle),
        cursor: 'pointer',
        minHeight: props.showImage ? '156px' : '44px',
        background: 'rgba(255,255,255,0.04)',
      }}
      onClick={props.onClick}
    >
      {props.showImage ? (
        <>
          <Box
            style={{
              position: 'relative',
              height: '108px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: 'rgba(255,255,255,0.18)',
              marginBottom: '6px',
            }}
          >
            {canRotate ? (
              <>
                <Button
                  compact
                  icon="arrow-left"
                  style={{ position: 'absolute', top: '6px', left: '6px', minWidth: '24px', width: '24px', height: '24px', padding: 0 }}
                  onClick={(event) => {
                    event.stopPropagation();
                    rotatePreview(-1);
                  }}
                />
                <Button
                  compact
                  icon="arrow-right"
                  style={{ position: 'absolute', top: '6px', right: '6px', minWidth: '24px', width: '24px', height: '24px', padding: 0 }}
                  onClick={(event) => {
                    event.stopPropagation();
                    rotatePreview(1);
                  }}
                />
              </>
            ) : null}
            {currentBaseAsset ? (
              <Box
                style={{
                  position: 'relative',
                  width: '84px',
                  height: '84px',
                }}
              >
                <Box style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <PixelPreview
                    asset={currentBaseAsset}
                    token={props.token}
                    alt={`${props.option.name} base`}
                    width="84px"
                    height="84px"
                  />
                </Box>
                <Box
                  style={{
                    position: 'absolute',
                    inset: 0,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    transform: `translateY(${props.overlayOffsetY || 0}px)`,
                  }}
                >
                  <PixelPreview
                    asset={currentAsset}
                    token={props.token}
                    alt={props.option.name}
                    width="84px"
                    height="84px"
                    fallback={null}
                  />
                </Box>
              </Box>
            ) : (
              <PixelPreview
                asset={currentAsset}
                token={props.token}
                alt={props.option.name}
                width="84px"
                height="84px"
                fallback={props.option.icon ? (
                  <DmIcon icon={props.option.icon} icon_state={props.option.icon_state || ''} width="96px" height="96px" />
                ) : (
                  <Box color="label">Нет</Box>
                )}
              />
            )}
          </Box>
          <Box textAlign="center" style={{ lineHeight: 1.08, overflowWrap: 'anywhere', fontSize: '14px' }}>
            {props.option.name}
          </Box>
        </>
      ) : (
        <Box>{props.option.name}</Box>
      )}
    </Box>
  );
};

const HairControlButton = (props: {

  label: string;
  value?: string | null;
  color?: string | null;
  onClick: () => void;
}) => (
  <Button compact onClick={props.onClick} style={{ minWidth: '112px' }}>
    <Box inline mr={0.35}>{props.label}</Box>
    <Box inline bold>{props.value || 'Нет'}{swatch(props.color)}</Box>
  </Button>
);

const FeatureModal = (props: {
  data: Data;
  active: ActiveCustomizer | null;
  act: (action: string, payload?: Record<string, unknown>) => void;
  onClose: () => void;
}) => {
  const active = props.active;
  const [search, setSearch] = useState(active?.search_query || '');

  useEffect(() => {
    setSearch(active?.search_query || '');
  }, [active?.id, active?.search_query]);

  useEffect(() => {
    if (!active || active.group === 'simple') {
      return;
    }
    const timeout = setTimeout(() => {
      if (search !== (active.search_query || '')) {
        props.act('set_customizer_filter', { value: search });
      }
    }, 250);
    return () => clearTimeout(timeout);
  }, [search, active?.id, active?.search_query, active?.group, props]);

  if (!active) {
    return (
      <ModalShell title="Особенность" width="420px" onClose={props.onClose}>
        <Box color="label">Загрузка настройки...</Box>
      </ModalShell>
    );
  }

  const isSimple = active.group === 'simple';
  const modalWidth = isSimple ? '760px' : '820px';

  return (
    <ModalShell title={active.name} width={modalWidth} onClose={props.onClose}>
      <Box mb={0.6} p={0.6} style={cardStyle}>
        <Box color="label">Текущий вариант</Box>
        <Box bold>{active.current_accessory_name || 'Нет'}</Box>
      </Box>

      {active.can_change_choice && active.choice_groups?.length ? (
        <Box mb={0.6} p={0.5} style={cardStyle}>
          {active.choice_groups.map((group) => (
            <Button
              key={group.id}
              mr={0.4}
              mb={0.4}
              selected={group.current}
              onClick={() => props.act('set_customizer_choice', { customizer: active.id, choice: group.id })}
            >
              {group.name}
            </Button>
          ))}
        </Box>
      ) : null}

      {isSimple ? (
        <>
          <Stack mb={0.6} align="center">
            <Stack.Item grow>
              <select
                value={active.selected_accessory_id || ''}
                onChange={(event) => props.act('set_customizer_accessory', { customizer: active.id, accessory: event.currentTarget.value })}
                style={{
                  width: '100%',
                  height: '34px',
                  background: 'rgba(255,255,255,0.06)',
                  color: 'white',
                  border: '1px solid rgba(255,255,255,0.18)',
                  padding: '4px 8px',
                }}
              >
                {active.options.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.name}
                  </option>
                ))}
              </select>
            </Stack.Item>
            {active.allows_disabling ? (
              <Stack.Item>
                <Button onClick={() => props.act('toggle_customizer', { customizer: active.id })}>
                  {active.disabled ? 'Включить' : 'Выключить'}
                </Button>
              </Stack.Item>
            ) : null}
          </Stack>

          {active.allows_accessory_color_customization && active.accessory_color_labels?.length ? (
            <Box mb={0.6}>
              {active.accessory_color_labels.map((label, index) => (
                <CompactRow
                  key={`${label}-${index}`}
                  label={label}
                  value={active.accessory_color_values?.[index] || 'Нет'}
                  colorPreview={active.accessory_color_values?.[index]}
                  onClick={() => props.act('edit_accessory_color', { customizer: active.id, index: index + 1 })}
                />
              ))}
            </Box>
          ) : null}

          <Section title="Все варианты" fill scrollable>
            <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '8px' }}>
              {active.options.map((option) => (
                <Button
                  key={option.id}
                  selected={option.id === active.selected_accessory_id}
                  textAlign="left"
                  style={{ minHeight: '34px' }}
                  onClick={() => props.act('set_customizer_accessory', { customizer: active.id, accessory: option.id })}
                >
                  {option.name}
                </Button>
              ))}
            </Box>
          </Section>
        </>
      ) : (
        <>
          <Stack mb={0.6} align="center">
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Поиск..."
                value={search}
                onChange={setSearch}
              />
            </Stack.Item>
            {active.allows_disabling ? (
              <Stack.Item>
                <Button onClick={() => props.act('toggle_customizer', { customizer: active.id })}>
                  {active.disabled ? 'Включить' : 'Выключить'}
                </Button>
              </Stack.Item>
            ) : null}
            <Stack.Item>
              <Button onClick={() => props.act('reset_customizer_colors', { customizer: active.id })}>Сброс</Button>
            </Stack.Item>
          </Stack>

          {active.is_hair ? (
            <Box mb={0.6} p={0.5} style={cardStyle}>
              <Box color="label" mb={0.4}>Цвет и градиенты</Box>
              <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                <HairControlButton label="Основа" value={active.hair_color} color={active.hair_color} onClick={() => props.act('set_hair_color', { customizer: active.id })} />
                <HairControlButton label="Нат. градиент" value={active.natural_gradient} onClick={() => props.act('set_natural_gradient', { customizer: active.id })} />
                <HairControlButton label="Цвет нат." value={active.natural_color} color={active.natural_color} onClick={() => props.act('set_natural_color', { customizer: active.id })} />
                <HairControlButton label="Градиент краски" value={active.dye_gradient} onClick={() => props.act('set_dye_gradient', { customizer: active.id })} />
                <HairControlButton label="Цвет краски" value={active.dye_color} color={active.dye_color} onClick={() => props.act('set_dye_color', { customizer: active.id })} />
              </Box>
            </Box>
          ) : null}

          {active.allows_accessory_color_customization && active.accessory_color_labels?.length ? (
            <Box mb={0.6}>
              {active.accessory_color_labels.map((label, index) => (
                <CompactRow
                  key={`${label}-${index}`}
                  label={label}
                  value={active.accessory_color_values?.[index] || 'Нет'}
                  colorPreview={active.accessory_color_values?.[index]}
                  onClick={() => props.act('edit_accessory_color', { customizer: active.id, index: index + 1 })}
                />
              ))}
            </Box>
          ) : null}

          {(() => {
            const pageSize = active.window_size || Math.max(active.options.length, 1);
            const totalPages = Math.max(1, Math.ceil((active.total_filtered || 0) / pageSize));
            const currentPage = Math.max(1, Math.ceil(((active.window_start || 1) - 1) / pageSize) + 1);
            const prevStart = Math.max(1, (active.window_start || 1) - pageSize);
            const nextStart = Math.min(
              Math.max(1, (active.total_filtered || 1) - pageSize + 1),
              (active.window_start || 1) + pageSize,
            );

            return (
              <>
                {totalPages > 1 ? (
                  <Stack mb={0.5} align="center">
                    <Stack.Item>
                      <Button
                        disabled={currentPage <= 1}
                        onClick={() => props.act('set_customizer_window', { start: prevStart })}
                      >
                        ←
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Box textAlign="center">Страница {currentPage} / {totalPages}</Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        disabled={currentPage >= totalPages}
                        onClick={() => props.act('set_customizer_window', { start: nextStart })}
                      >
                        →
                      </Button>
                    </Stack.Item>
                  </Stack>
                ) : null}

                <Box
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(4, minmax(0, 1fr))',
                    gap: '8px',
                    maxHeight: '560px',
                    overflowY: 'auto',
                  }}
                >
                  {active.options.map((option) => (
                    <OptionTile
                      key={option.id}
                      option={option}
                      customizerId={active.id}
                      selected={option.id === active.selected_accessory_id}
                      showImage
                      token={props.data.preview_token}
                      rotatable={!!active.is_hair}
                      headBaseAssetsByDir={active.is_hair ? active.head_base_assets_by_dir : undefined}
                      overlayOffsetY={active.overlay_offset_y}
                      onClick={() => props.act('set_customizer_accessory', { customizer: active.id, accessory: option.id })}
                    />
                  ))}
                </Box>
              </>
            );
          })()}
        </>
      )}
    </ModalShell>
  );
};

const GenderChoiceButton = (props: {
  label: string;
  selected?: boolean;
  onClick: () => void;
}) => (
  <Button selected={props.selected} onClick={props.onClick} style={{ minWidth: '140px' }}>
    {props.label}
  </Button>
);


const filterSelectionOptions = (options: SelectionOption[], search: string) => {
  const needle = search.trim().toLowerCase();
  if (!needle) {
    return options;
  }
  return options.filter((option) => {
    const blob = `${option.name} ${option.description || ''} ${option.meta || ''}`.toLowerCase();
    return blob.includes(needle);
  });
};


const ContextDropdownRow = (props: {
  label: string;
  selector?: ContextSelector;
  onSelected: (value: string) => void;
  disabled?: boolean;
  auxButton?: ReactNode;
  labelBasis?: string;
}) => {
  const optionItems = (props.selector?.options || []).map((option) => ({
    displayText: option.meta ? `${option.name} — ${option.meta}` : option.name,
    value: option.id,
  }));

  return (
    <Box mb={0.35} p={0.35} style={cardStyle}>
      <Stack align="center">
        <Stack.Item basis={props.labelBasis || '180px'} shrink={0}>
          <Box color="label">{props.label}</Box>
        </Stack.Item>
        {props.auxButton ? (
          <Stack.Item shrink={0} mr={0.35}>
            {props.auxButton}
          </Stack.Item>
        ) : null}
        <Stack.Item grow>
          <Dropdown
            width="100%"
            options={optionItems}
            selected={props.selector?.current || (optionItems[0]?.displayText ?? 'Нет вариантов')}
            disabled={props.disabled || !optionItems.length}
            onSelected={(value) => props.onSelected(String(value))}
          />
        </Stack.Item>
      </Stack>
    </Box>
  );
};


const SearchableSelectorModal = (props: {
  title: string;
  selector?: ContextSelector;
  onSelected: (value: string) => void;
  onClose: () => void;
}) => {
  const [search, setSearch] = useState('');
  const filtered = useMemo(
    () => filterSelectionOptions(props.selector?.options || [], search),
    [props.selector?.options, search],
  );

  return (
    <ModalShell title={props.title} width="980px" onClose={props.onClose}>
      <Box mb={0.6} p={0.6} style={cardStyle}>
        <Box color="label">Текущий вариант</Box>
        <Box bold>{props.selector?.current || 'Не выбран'}</Box>
      </Box>
      <Box mb={0.6}>
        <Input fluid placeholder="Поиск..." value={search} onChange={setSearch} />
      </Box>
      <Section title="Варианты">
        <Box style={{ maxHeight: '560px', overflowY: 'auto' }}>
          {filtered.length ? filtered.map((option) => (
            <Button
              key={option.id}
              fluid
              textAlign="left"
              selected={!!option.current}
              mb={0.35}
              p={0.5}
              onClick={() => props.onSelected(option.id)}
            >
              <Box bold>{option.name}</Box>
              {option.meta ? <Box color="label">{option.meta}</Box> : null}
              {option.description ? <Box color="label" style={{ whiteSpace: 'normal' }}>{option.description}</Box> : null}
            </Button>
          )) : <Box color="label">Ничего не найдено.</Box>}
        </Box>
      </Section>
    </ModalShell>
  );
};

const VicesModal = (props: {
  options: ViceOption[];
  limit?: number;
  act: (action: string, payload?: Record<string, unknown>) => void;
  onClose: () => void;
}) => {
  const [search, setSearch] = useState('');
  const selected = props.options.filter((option) => option.selected);
  const filtered = useMemo(() => {
    const needle = search.trim().toLowerCase();
    return props.options.filter((option) => {
      if (option.selected) {
        return false;
      }
      if (!needle) {
        return true;
      }
      return `${option.name} ${option.description || ''}`.toLowerCase().includes(needle);
    });
  }, [props.options, search]);
  const canAddMore = selected.length < (props.limit || 0);

  return (
    <ModalShell title="Пороки" width="980px" onClose={props.onClose}>
      <Box mb={0.6} p={0.6} style={cardStyle}>
        <Box color="label">Выбрано</Box>
        <Box bold>{selected.length} / {props.limit || 0}</Box>
      </Box>
      <Section title="Текущие пороки" mb={0.6}>
        <Box style={{ maxHeight: '220px', overflowY: 'auto' }}>
          {selected.length ? selected.map((option) => (
            <Box key={`selected-${option.id}`} mb={0.4} p={0.5} style={cardStyle}>
              <Stack align="center">
                <Stack.Item grow>
                  <Box bold>{option.name}</Box>
                  {option.description ? <Box color="label" style={{ whiteSpace: 'normal' }}>{option.description}</Box> : null}
                </Stack.Item>
                <Stack.Item>
                  <Button compact onClick={() => props.act('remove_charflaw_type', { flaw: option.id })}>Убрать</Button>
                </Stack.Item>
              </Stack>
            </Box>
          )) : <Box color="label">Пока ничего не выбрано.</Box>}
        </Box>
      </Section>
      <Box mb={0.6}>
        <Input fluid placeholder="Поиск порока..." value={search} onChange={setSearch} />
      </Box>
      <Section title="Доступные пороки">
        <Box style={{ maxHeight: '420px', overflowY: 'auto' }}>
          {filtered.map((option) => (
            <Box key={option.id} mb={0.4} p={0.5} style={cardStyle}>
              <Stack align="center">
                <Stack.Item grow>
                  <Box bold>{option.name}</Box>
                  {option.description ? <Box color="label" style={{ whiteSpace: 'normal' }}>{option.description}</Box> : null}
                </Stack.Item>
                <Stack.Item>
                  {option.selected ? (
                    <Button compact onClick={() => props.act('remove_charflaw_type', { flaw: option.id })}>Убрать</Button>
                  ) : (
                    <Button compact disabled={!canAddMore} onClick={() => props.act('add_charflaw', { flaw: option.id })}>Добавить</Button>
                  )}
                </Stack.Item>
              </Stack>
            </Box>
          ))}
          {!filtered.length ? <Box color="label">Ничего не найдено.</Box> : null}
        </Box>
      </Section>
    </ModalShell>
  );
};


const DescriptorsModal = (props: {
  data?: DescriptorEditorData;
  act: (action: string, payload?: Record<string, unknown>) => void;
  onClose: () => void;
}) => {
  const [contentDrafts, setContentDrafts] = useState<Record<number, string>>({});

  useEffect(() => {
    const drafts: Record<number, string> = {};
    (props.data?.custom_entries || []).forEach((entry) => {
      drafts[entry.index] = entry.content || '';
    });
    setContentDrafts(drafts);
  }, [props.data]);

  return (
    <ModalShell title="Дескрипторы" width="980px" onClose={props.onClose}>
      <Section title="Основные дескрипторы" mb={0.6}>
        <Box style={{ maxHeight: '300px', overflowY: 'auto' }}>
          {(props.data?.entries || []).map((entry) => (
            <Box key={entry.id} mb={0.5} p={0.5} style={cardStyle}>
              <Stack align="center">
                <Stack.Item basis="220px" shrink={0}>
                  <Box color="label">{entry.name}</Box>
                  <Box bold>{entry.value}</Box>
                </Stack.Item>
                <Stack.Item grow>
                  <Dropdown
                    width="100%"
                    options={entry.options.map((option) => ({ displayText: option.name, value: option.id }))}
                    selected={entry.value}
                    onSelected={(value) => props.act('set_descriptor_choice', { choice: entry.id, descriptor: value })}
                  />
                </Stack.Item>
              </Stack>
            </Box>
          ))}
          {!(props.data?.entries || []).length ? <Box color="label">Нет доступных дескрипторов.</Box> : null}
        </Box>
      </Section>
      <Section title="Кастомные дескрипторы">
        <Box style={{ maxHeight: '320px', overflowY: 'auto' }}>
          {(props.data?.custom_entries || []).filter((entry) => entry.visible).length ? (
            (props.data?.custom_entries || []).filter((entry) => entry.visible).map((entry) => (
              <Box key={`custom-${entry.index}`} mb={0.5} p={0.5} style={cardStyle}>
                <Box bold mb={0.4}>Кастом #{entry.index}</Box>
                <Stack align="center" mb={0.4}>
                  <Stack.Item basis="220px" shrink={0}>
                    <Dropdown
                      width="100%"
                      options={entry.prefix_options.map((option) => ({ displayText: option.name, value: option.id }))}
                      selected={entry.prefix_label}
                      onSelected={(value) => props.act('set_custom_descriptor_prefix', { index: entry.index, prefix: value })}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <input
                      value={contentDrafts[entry.index] ?? ''}
                      onChange={(event) => setContentDrafts((current) => ({ ...current, [entry.index]: event.currentTarget.value }))}
                      style={{ width: '100%', height: '34px', background: 'rgba(255,255,255,0.06)', color: 'white', border: '1px solid rgba(255,255,255,0.18)', padding: '4px 8px' }}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button compact onClick={() => props.act('set_custom_descriptor_content', { index: entry.index, value: contentDrafts[entry.index] ?? '' })}>Сохранить</Button>
                  </Stack.Item>
                </Stack>
              </Box>
            ))
          ) : (
            <Box color="label">Для текущих дескрипторов кастомные поля не используются.</Box>
          )}
        </Box>
      </Section>
    </ModalShell>
  );
};


const CulinaryModal = (props: {
  data?: CulinaryEditorData;
  act: (action: string, payload?: Record<string, unknown>) => void;
  onClose: () => void;
}) => {
  const entries = props.data?.entries || [];
  const [activeKey, setActiveKey] = useState(entries[0]?.key || '');
  const [search, setSearch] = useState('');

  useEffect(() => {
    if (!entries.length) {
      return;
    }
    if (!activeKey || !entries.find((entry) => entry.key === activeKey)) {
      setActiveKey(entries[0].key);
    }
  }, [entries, activeKey]);

  const activeEntry = entries.find((entry) => entry.key === activeKey);
  const filteredOptions = useMemo(() => filterSelectionOptions(activeEntry?.options || [], search), [activeEntry?.options, search]);

  return (
    <ModalShell title="Предпочтения в еде" width="1120px" onClose={props.onClose}>
      <Stack>
        <Stack.Item basis="42%">
          <Section title="Текущие предпочтения">
            <Box style={{ maxHeight: '560px', overflowY: 'auto' }}>
              {entries.map((entry) => (
                <Button
                  key={entry.key}
                  fluid
                  selected={entry.key === activeKey}
                  textAlign="left"
                  mb={0.4}
                  p={0.55}
                  onClick={() => { setActiveKey(entry.key); setSearch(''); }}
                >
                  <Box color="label">{entry.label}</Box>
                  <Box bold>{entry.value}</Box>
                </Button>
              ))}
              <Box mt={0.6}>
                <Button fluid onClick={() => props.act('reset_culinary_preferences')}>Сбросить к дефолту</Button>
              </Box>
            </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section title={activeEntry ? `Выбор: ${activeEntry.label}` : 'Выбор'}>
            <Box style={{ maxHeight: '560px', overflowY: 'auto' }}>
              {activeEntry ? (
                <>
                  <Box mb={0.6}>
                    <Input fluid placeholder="Поиск..." value={search} onChange={setSearch} />
                  </Box>
                  {activeEntry.mode === 'food' ? (
                    <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '8px' }}>
                      {filteredOptions.map((option) => (
                        <Button
                          key={`${activeEntry.key}-${option.id}`}
                          textAlign="center"
                          style={{ minHeight: '132px' }}
                          onClick={() => props.act('set_culinary_preference', { preference_type: activeEntry.key, mode: activeEntry.mode, value: option.id })}
                        >
                          <Box mb={0.35} style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '70px' }}>
                            {option.icon ? (
                              <DmIcon icon={option.icon} icon_state={option.icon_state || ''} width="64px" height="64px" />
                            ) : (
                              <Box color="label">Нет</Box>
                            )}
                          </Box>
                          <Box bold style={{ lineHeight: 1.05 }}>{option.name}</Box>
                          {option.meta ? <Box color="label">{option.meta}</Box> : null}
                        </Button>
                      ))}
                    </Box>
                  ) : (
                    <>
                      {filteredOptions.map((option) => (
                        <Button
                          key={`${activeEntry.key}-${option.id}`}
                          fluid
                          textAlign="left"
                          mb={0.35}
                          p={0.5}
                          onClick={() => props.act('set_culinary_preference', { preference_type: activeEntry.key, mode: activeEntry.mode, value: option.id })}
                        >
                          <Box bold>{option.name}</Box>
                          {option.meta ? <Box color="label">{option.meta}</Box> : null}
                        </Button>
                      ))}
                    </>
                  )}
                  {!filteredOptions.length ? <Box color="label">Ничего не найдено.</Box> : null}
                </>
              ) : <Box color="label">Выберите слот предпочтения слева.</Box>}
            </Box>
          </Section>
        </Stack.Item>
      </Stack>
    </ModalShell>
  );
};


const FamiliarModal = (props: {
  data?: FamiliarEditorData;
  act: (action: string, payload?: Record<string, unknown>) => void;
  onClose: () => void;
}) => {
  const [name, setName] = useState(props.data?.familiar_name || '');
  const [headshot, setHeadshot] = useState(props.data?.familiar_headshot_link || '');
  const [flavor, setFlavor] = useState(props.data?.familiar_flavortext || '');
  const [ooc, setOoc] = useState(props.data?.familiar_ooc_notes || '');
  const [extra, setExtra] = useState(props.data?.familiar_ooc_extra_link || '');

  useEffect(() => {
    setName(props.data?.familiar_name || '');
    setHeadshot(props.data?.familiar_headshot_link || '');
    setFlavor(props.data?.familiar_flavortext || '');
    setOoc(props.data?.familiar_ooc_notes || '');
    setExtra(props.data?.familiar_ooc_extra_link || '');
  }, [props.data]);

  return (
    <ModalShell title="Настройки фамильяра" width="1020px" onClose={props.onClose}>
      <Stack>
        <Stack.Item basis="40%">
          <Section title="Основное">
            <Box style={{ maxHeight: '620px', overflowY: 'auto' }}>
              <Box mb={0.5} p={0.5} style={cardStyle}>
                <Box color="label">Тип</Box>
                <Dropdown
                  width="100%"
                  mt={0.35}
                  options={(props.data?.species_options || []).map((option) => ({ displayText: option.name, value: option.id }))}
                  selected={props.data?.familiar_specie || 'None selected'}
                  onSelected={(value) => props.act('set_familiar_specie', { value })}
                />
                {props.data?.lore_blurb ? <Box mt={0.45} color="label" style={{ whiteSpace: 'normal' }}>{props.data.lore_blurb}</Box> : null}
              </Box>
              <Box mb={0.5} p={0.5} style={cardStyle}>
                <Box color="label">Местоимения</Box>
                <Dropdown
                  width="100%"
                  mt={0.35}
                  options={(props.data?.pronoun_options || []).map((option) => ({ displayText: option.name, value: option.id }))}
                  selected={props.data?.familiar_pronouns || 'they/them'}
                  onSelected={(value) => props.act('set_familiar_pronouns', { value })}
                />
              </Box>
              <Box mb={0.5} p={0.5} style={cardStyle}>
                <Box color="label" mb={0.35}>Имя</Box>
                <input value={name} onChange={(event) => setName(event.currentTarget.value)} style={{ width: '100%', height: '34px', background: 'rgba(255,255,255,0.06)', color: 'white', border: '1px solid rgba(255,255,255,0.18)', padding: '4px 8px' }} />
                <Box mt={0.4}><Button fluid onClick={() => props.act('set_familiar_name', { value: name })}>Сохранить имя</Button></Box>
              </Box>
              <Box mb={0.5} p={0.5} style={cardStyle}>
                <Box color="label" mb={0.35}>Headshot URL</Box>
                <input value={headshot} onChange={(event) => setHeadshot(event.currentTarget.value)} style={{ width: '100%', height: '34px', background: 'rgba(255,255,255,0.06)', color: 'white', border: '1px solid rgba(255,255,255,0.18)', padding: '4px 8px' }} />
                <Box mt={0.4}><Button fluid onClick={() => props.act('set_familiar_headshot', { value: headshot })}>Сохранить портрет</Button></Box>
              </Box>
              {props.data?.familiar_headshot_link ? (
                <Box textAlign="center" mt={0.4}>
                  <img src={props.data.familiar_headshot_link} alt="Familiar headshot" style={{ maxWidth: '100%', maxHeight: '240px' }} />
                </Box>
              ) : null}
              <Box mt={0.6}>
                <Button fluid onClick={() => props.act('toggle_familiar_queue')}>
                  {props.data?.queue_joined ? 'Выйти из очереди' : 'Встать в очередь'}
                </Button>
              </Box>
            </Box>
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section title="Описание">
            <Box style={{ maxHeight: '620px', overflowY: 'auto' }}>
              <Box mb={0.5}>
                <Box color="label" mb={0.35}>Флавортекст</Box>
                <textarea value={flavor} onChange={(event) => setFlavor(event.currentTarget.value)} style={{ width: '100%', minHeight: '160px', background: 'rgba(255,255,255,0.06)', color: 'white', border: '1px solid rgba(255,255,255,0.18)', padding: '8px' }} />
                <Box mt={0.35}><Button fluid onClick={() => props.act('set_familiar_flavortext', { value: flavor })}>Сохранить флавор</Button></Box>
              </Box>
              <Box mb={0.5}>
                <Box color="label" mb={0.35}>OOC заметки</Box>
                <textarea value={ooc} onChange={(event) => setOoc(event.currentTarget.value)} style={{ width: '100%', minHeight: '130px', background: 'rgba(255,255,255,0.06)', color: 'white', border: '1px solid rgba(255,255,255,0.18)', padding: '8px' }} />
                <Box mt={0.35}><Button fluid onClick={() => props.act('set_familiar_ooc_notes', { value: ooc })}>Сохранить OOC заметки</Button></Box>
              </Box>
              <Box mb={0.5}>
                <Box color="label" mb={0.35}>OOC Extra URL</Box>
                <input value={extra} onChange={(event) => setExtra(event.currentTarget.value)} style={{ width: '100%', height: '34px', background: 'rgba(255,255,255,0.06)', color: 'white', border: '1px solid rgba(255,255,255,0.18)', padding: '4px 8px' }} />
                <Box mt={0.35}><Button fluid onClick={() => props.act('set_familiar_ooc_extra', { value: extra })}>Сохранить OOC Extra</Button></Box>
              </Box>
            </Box>
          </Section>
        </Stack.Item>
      </Stack>
    </ModalShell>
  );
};

const GenderModal = (props: {
  data: Data;
  onApplyPreset: (preset: 'masculine' | 'feminine') => void;
  onSetBodyType: (gender: 'masculine' | 'feminine') => void;
  onSetVoiceType: (voiceType: string) => void;
  onEditPreference: (preference: string) => void;
  onClose: () => void;
}) => {
  const bodyIsFeminine = !!props.data.appearance.body_is_feminine;

  return (
    <ModalShell title="Тело и голос" width="900px" onClose={props.onClose}>
      <Section title="Пресеты" fitted>
        <Stack>
          <Stack.Item grow>
            <Button fluid onClick={() => props.onApplyPreset('masculine')}>Мужской пресет</Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button fluid onClick={() => props.onApplyPreset('feminine')}>Женский пресет</Button>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Тело и обращение" mt={0.75} fitted>
        <Box mb={0.6}>
          <Box color="label" mb={0.35}>Тип тела</Box>
          <Stack>
            <Stack.Item>
              <GenderChoiceButton label="Маскулинное" selected={!bodyIsFeminine} onClick={() => props.onSetBodyType('masculine')} />
            </Stack.Item>
            <Stack.Item>
              <GenderChoiceButton label="Фемининное" selected={bodyIsFeminine} onClick={() => props.onSetBodyType('feminine')} />
            </Stack.Item>
          </Stack>
        </Box>

        <Box mb={0.6}>
          <Box color="label" mb={0.35}>Гендер голоса</Box>
          <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {(props.data.voice_type_choices || []).map((voiceName) => {
              const lower = voiceName.toLowerCase();
              let label = voiceName;
              if (lower.includes('androg')) {
                label = 'Андрогинный';
              } else if (lower.includes('fem')) {
                label = 'Женский';
              } else if (lower.includes('masc') || lower.includes('male')) {
                label = 'Мужской';
              }
              return (
                <GenderChoiceButton
                  key={voiceName}
                  label={label}
                  selected={props.data.identity.voice_type === voiceName}
                  onClick={() => props.onSetVoiceType(voiceName)}
                />
              );
            })}
          </Box>
        </Box>

        <CompactRow label="Титулы" value={translateChoiceValue(props.data.identity.titles)} onClick={() => props.onEditPreference('titles')} />
        <CompactRow label="Местоимения" value={translateChoiceValue(props.data.identity.pronouns)} onClick={() => props.onEditPreference('pronouns')} />
        <CompactRow label="Тип одежды" value={translateChoiceValue(props.data.identity.clothes)} onClick={() => props.onEditPreference('clothespref')} />
      </Section>
    </ModalShell>
  );
};

const LeftQuickEdit = (props: {
  data: Data;
  onEditPreference: (preference: string) => void;
  onOpenGenderMenu: () => void;
}) => (
  <Box mt={0.6}>
    <CompactRow label="Имя" value={props.data.identity.real_name} onClick={() => props.onEditPreference('name')} />
    <CompactRow label="Раса" value={`${props.data.appearance.species} / ${props.data.appearance.subspecies}`} onClick={() => props.onEditPreference('species')} />
    <CompactRow label="Пол" value={props.data.appearance.gender_label} onClick={props.onOpenGenderMenu} />
  </Box>
);

const LeftPane = (props: {
  data: Data;
  onRotate: (step: number) => void;
  rotatePending?: boolean;
  onOpenPlayerQuality: () => void;
  onOpenTriumphs: () => void;
  onPreviewFlavor: () => void;
  onEditPreference: (preference: string) => void;
  onOpenGenderMenu: () => void;
}) => (
  <Stack vertical fill>
    <Stack.Item>
      <Section title="Персонаж" fitted>
        <Box
          p={1}
          style={{
            minHeight: '388px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            border: '1px solid rgba(255,255,255,0.1)',
          }}
        >
          <PixelPreview
            asset={props.data.preview_asset}
            token={props.data.preview_token}
            alt="Предпросмотр персонажа"
            width="292px"
            height="388px"
            fallback={<Box color="label">Нет</Box>}
          />
        </Box>
        <Stack mt={0.5}>
          <Stack.Item grow>
            <Button fluid icon="undo" disabled={props.rotatePending} onClick={() => props.onRotate(-1)}>Повернуть влево</Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button fluid icon="redo" disabled={props.rotatePending} onClick={() => props.onRotate(1)}>Повернуть вправо</Button>
          </Stack.Item>
        </Stack>
        <Box mt={0.75}>Слот {props.data.loaded_slot}/{props.data.max_save_slots}</Box>
        <LeftQuickEdit data={props.data} onEditPreference={props.onEditPreference} onOpenGenderMenu={props.onOpenGenderMenu} />
      </Section>
    </Stack.Item>
    <Stack.Item grow>
      <Section title="Сводка" fill scrollable>
        <Stack vertical>
          <Stack.Item>
            <Button fluid onClick={props.onOpenPlayerQuality}>
              PQ: {props.data.player_quality}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button fluid onClick={props.onOpenTriumphs}>
              Триумфы: {(props.data.triumphs === '' || props.data.triumphs === null || props.data.triumphs === undefined || props.data.triumphs === '—') ? 0 : props.data.triumphs}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button fluid onClick={props.onPreviewFlavor}>
              Предпросмотр флавора
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </Stack.Item>
  </Stack>
);

const Subhead = (props: { children: ReactNode }) => (
  <Box mt={0.6} mb={0.35} bold color="label">
    {props.children}
  </Box>
);

const notesFormattingExamples = [
  { code: '\\', text: 'экранирует специальные символы' },
  { code: '# text', text: 'заголовок' },
  { code: '|text|', text: 'центрирование текста' },
  { code: '**text**', text: 'жирный текст' },
  { code: '*text*', text: 'курсив' },
  { code: '^text^', text: 'крупный текст' },
  { code: '((text))', text: 'уменьшенный текст' },
  { code: '* item', text: 'элемент списка' },
  { code: '---', text: 'горизонтальная линия' },
  { code: '-=FFFFFFtext=-', text: 'цветной текст' },
];

const renderImagePreviewGrid = (images?: string[], emptyText = 'Нет изображений.') => (
  <Box mt={0.5}>
    {images?.length ? (
      <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '6px' }}>
        {images.map((image, index) => (
          <Box key={`${image}-${index}`} p={0.25} style={cardStyle}>
            <a href={image} target="_blank" rel="noreferrer">
              <img src={image} alt={`Preview ${index + 1}`} style={{ width: '100%', height: '120px', objectFit: 'cover', display: 'block' }} />
            </a>
          </Box>
        ))}
      </Box>
    ) : (
      <Box color="label">{emptyText}</Box>
    )}
  </Box>
);

const GeneralTab = (props: {
  data: Data;
  onEditPreference: (preference: string) => void;
  onManageVices: () => void;
  onOpenDescriptors: () => void;
  onOpenCulinary: () => void;
  onOpenFamiliar: () => void;
  onOpenCombatMusic: () => void;
  act: (action: string, payload?: Record<string, unknown>) => void;
}) => (
  <Stack fill>
    <Stack.Item basis="56%">
      <Stack vertical fill>
        <Stack.Item basis="58%">
          <Section title="Общее" fill scrollable>
            <CompactRow
              label="Прозвище"
              value={props.data.identity.nickname}
              onClick={() => props.onEditPreference('nickname')}
              auxButton={(
                <PaletteButton
                  color={props.data.identity.highlight_color}
                  onClick={() => props.onEditPreference('highlight_color')}
                />
              )}
            />
            <CompactRow label="Происхождение" value={props.data.appearance.origin} onClick={() => props.onEditPreference('origin')} />
            <ContextDropdownRow
              label="Возраст"
              selector={props.data.context_selectors?.age}
              onSelected={(value) => props.act('set_context_preference', { kind: 'age', value })}
            />
            <ContextDropdownRow
              label="Вера"
              selector={props.data.context_selectors?.faith}
              onSelected={(value) => props.act('set_context_preference', { kind: 'faith', value })}
            />
            <ContextDropdownRow
              label="Покровитель"
              selector={props.data.context_selectors?.patron}
              onSelected={(value) => props.act('set_context_preference', { kind: 'patron', value })}
            />
            <ContextDropdownRow
              label="Доп. язык"
              selector={props.data.context_selectors?.extra_language}
              onSelected={(value) => props.act('set_context_preference', { kind: 'extra_language', value })}
            />
            <ContextDropdownRow
              label="Акцент"
              selector={props.data.context_selectors?.char_accent}
              onSelected={(value) => props.act('set_context_preference', { kind: 'char_accent', value })}
            />
            <CompactRow label="Дескрипторы" value="Открыть" onClick={props.onOpenDescriptors} />
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section title="Голос" fill scrollable>
            <ContextDropdownRow
              label="Голосовой пак"
              selector={props.data.context_selectors?.voicepack}
              onSelected={(value) => props.act('set_context_preference', { kind: 'voicepack', value })}
            />
            <SliderNumberRow
              label="Высота голоса"
              value={Number(props.data.identity.voice_pitch || 1)}
              min={props.data.identity.voice_pitch_min || 0.8}
              max={props.data.identity.voice_pitch_max || 1.35}
              step={0.01}
              paletteColor={props.data.identity.voice_color}
              onPaletteClick={() => props.onEditPreference('voice')}
              onCommit={(value) => props.act('set_voice_pitch_value', { value })}
            />
          </Section>
        </Stack.Item>
      </Stack>
    </Stack.Item>
    <Stack.Item grow>
      <Stack vertical fill>
        <Stack.Item basis="48%">
          <Section title="Черты" fill scrollable>
            <CompactRow
              label="Статпак"
              value={props.data.appearance.statpack || 'None'}
              onClick={() => props.onEditPreference('statpack')}
            />
            <ContextDropdownRow
              label="Особенность"
              selector={props.data.context_selectors?.virtue_primary}
              onSelected={(value) => props.act('set_context_preference', { kind: 'virtue_primary', value })}
            />
            {props.data.appearance.statpack_virtuous ? (
              <ContextDropdownRow
                label="Вторая особенность"
                selector={props.data.context_selectors?.virtue_secondary}
                onSelected={(value) => props.act('set_context_preference', { kind: 'virtue_secondary', value })}
              />
            ) : null}
            <CompactRow label="Пороки" value={props.data.virtues.vices.length ? props.data.virtues.vices.join(', ') : 'Открыть'} onClick={props.onManageVices} />
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section title="Разное" fill scrollable>
            <CompactRow label="Доминация руки" value={props.data.identity.domhand || 'Right-handed'} onClick={() => props.onEditPreference('domhand')} />
            <CompactRow label="Возможность воскрешать" value={props.data.identity.dnr_pref ? 'Нет' : 'Да'} onClick={() => props.onEditPreference('dnr')} />
            <CompactRow label="Боевая музыка" value={props.data.context_selectors?.combat_music?.current || 'Default'} onClick={props.onOpenCombatMusic} />
            <CompactRow label="Фамильяр" value="Открыть" onClick={props.onOpenFamiliar} />
            <CompactRow label="Предпочтения в еде" value="Открыть" onClick={props.onOpenCulinary} />
          </Section>
        </Stack.Item>
      </Stack>
    </Stack.Item>
  </Stack>
);

const NotesTab = (props: {
  data: Data;
  onEditPreference: (preference: string) => void;
  onEditTextField: (field: string) => void;
  act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const [showHelp, setShowHelp] = useState(false);

  return (
    <Stack fill>
      <Stack.Item basis="56%">
        <Section title="Описание" fill scrollable>
          <Box mb={0.55}>
            <Button icon={showHelp ? 'chevron-up' : 'chevron-down'} onClick={() => setShowHelp(!showHelp)}>
              Подсказки по форматированию
            </Button>
          </Box>
          {showHelp ? (
            <Box mb={0.7} p={0.7} style={cardStyle}>
              <Box color="label" mb={0.35}>Редактирование открывает то же текстовое окно, что и в старом HTML. Можно использовать следующие маркеры:</Box>
              {notesFormattingExamples.map((example) => (
                <Box key={example.code} style={{ lineHeight: 1.25 }}>
                  <Box as="span" mr={0.4} style={{ fontFamily: 'monospace' }}>{example.code}</Box>
                  <Box as="span" color="label">— {example.text}</Box>
                </Box>
              ))}
            </Box>
          ) : null}

          <CompactRow wrap label="Флавортекст" value={truncate(props.data.roleplay.flavortext, 120)} onClick={() => props.onEditTextField('flavortext')} />
          <CompactRow wrap label="OOC заметки" value={truncate(props.data.roleplay.ooc_notes, 120)} onClick={() => props.onEditTextField('ooc_notes')} />
          <CompactRow wrap label="Слухи" value={truncate(props.data.roleplay.rumour, 120)} onClick={() => props.onEditTextField('rumour')} />
          <CompactRow wrap label="Сплетни знати" value={truncate(props.data.roleplay.noble_gossip, 120)} onClick={() => props.onEditTextField('noble_gossip')} />
          <CompactRow wrap label="ERP предпочтения" value={truncate(props.data.roleplay.erpprefs, 120)} onClick={() => props.onEditTextField('erpprefs')} />
          <CompactRow wrap label="NSFW флавортекст" value={truncate(props.data.roleplay.nsfwflavortext, 120)} onClick={() => props.onEditTextField('nsfwflavortext')} />
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Галереи и музыка" fill scrollable>
          <CompactRow wrap label="Headshot" value={truncate(props.data.roleplay.headshot_link || 'Не задан', 72)} onClick={() => props.onEditTextField('headshot_link')} />
          {props.data.roleplay.headshot_link ? (
            <Box mt={0.45} mb={0.55} p={0.35} style={cardStyle}>
              <a href={props.data.roleplay.headshot_link} target="_blank" rel="noreferrer">
                <img src={props.data.roleplay.headshot_link} alt="Headshot" style={{ width: '100%', maxHeight: '320px', objectFit: 'contain', display: 'block' }} />
              </a>
            </Box>
          ) : null}
          <CompactRow label="SFW галерея" value={`${props.data.roleplay.sfw_gallery_count || 0}/3`} onClick={() => props.act('manage_gallery', { nsfw: 0 })} />
          {renderImagePreviewGrid(props.data.roleplay.sfw_gallery, 'SFW галерея пуста.')}
          <CompactRow label="NSFW галерея" value={`${props.data.roleplay.nsfw_gallery_count || 0}/3`} onClick={() => props.act('manage_gallery', { nsfw: 1 })} />
          {renderImagePreviewGrid(props.data.roleplay.nsfw_gallery, 'NSFW галерея пуста.')}
          <CompactRow wrap label="Музыка во флаворе" value={truncate(props.data.roleplay.music_url || 'Не задано', 72)} onClick={() => props.onEditPreference('ooc_extra')} />
          <CompactRow label="Исполнитель" value={props.data.roleplay.song_artist || 'Не задан'} onClick={() => props.onEditPreference('change_artist')} />
          <CompactRow label="Название трека" value={props.data.roleplay.song_title || 'Не задано'} onClick={() => props.onEditPreference('change_title')} />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const isNoneAccessoryValue = (value?: string | null) => !value || value === '__none__';

const ContextCustomizerRow = (props: {
  entry: SimpleCustomizer;
  act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const forceNoneOption = ['Пенис', 'Яички', 'Влагалище', 'Грудь'].includes(props.entry.name);
  const selectedValue = props.entry.selected_accessory_id || '__none__';
  const accessoryDisabled = isNoneAccessoryValue(selectedValue);
  const hasInlineColorButton = !!(props.entry.allows_accessory_color_customization && props.entry.accessory_color_labels?.length);
  const lockAccessorySelection = /душ/i.test(props.entry.name) || /soul/i.test(props.entry.name);
  const optionItems = [
    ...(props.entry.allows_disabling || forceNoneOption || accessoryDisabled ? [{ displayText: 'None', value: '__none__' }] : []),
    ...props.entry.options.map((option) => ({
      displayText: option.name,
      value: option.id,
    })),
  ];
  const currentChoice = props.entry.choice_groups?.find((group) => group.current);

  return (
    <Box mb={0.35} p={0.35} style={cardStyle}>
      <Stack align="center">
        <Stack.Item basis="124px" shrink={0}>
          <Box color="label">{props.entry.name}</Box>
        </Stack.Item>
        {hasInlineColorButton ? (
          <Stack.Item shrink={0} mr={0.35}>
            <PaletteButton
              color={getPrimaryCustomizerColor(props.entry)}
              disabled={accessoryDisabled}
              onClick={() => props.act('edit_accessory_color', { customizer: props.entry.id, index: 1 })}
            />
          </Stack.Item>
        ) : null}
        {!lockAccessorySelection && props.entry.can_change_choice && props.entry.choice_groups?.length ? (
          <Stack.Item basis="150px" shrink={0}>
            <Dropdown
              width="100%"
              options={props.entry.choice_groups.map((group) => ({ displayText: group.name, value: group.id }))}
              selected={currentChoice?.name || props.entry.choice_name}
              onSelected={(value) => props.act('set_customizer_choice', { customizer: props.entry.id, choice: value })}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item grow>
          {lockAccessorySelection ? (
            <Box px={0.7} py={0.45} style={cardStyle}>Цвет</Box>
          ) : (
            <Dropdown
              width="100%"
              options={optionItems}
              selected={accessoryDisabled ? 'None' : (props.entry.current_accessory_name || 'None')}
              onSelected={(value) => {
                if (value === '__none__') {
                  props.act('set_customizer_none', { customizer: props.entry.id });
                } else {
                  props.act('set_customizer_accessory', { customizer: props.entry.id, accessory: value });
                }
              }}
            />
          )}
        </Stack.Item>
      </Stack>
      {props.entry.size_var_name && !accessoryDisabled ? (
        <Box mt={0.3}>
          {props.entry.size_options?.length ? (
            <Box p={0.35} style={cardStyle}>
              <Stack align="center">
                <Stack.Item basis="180px" shrink={0}>
                  <Box color="label">{props.entry.size_label || 'Размер'}</Box>
                </Stack.Item>
                <Stack.Item grow>
                  <Dropdown
                    width="100%"
                    options={props.entry.size_options.map((option) => ({ displayText: option.name, value: option.id }))}
                    selected={props.entry.size_options.find((option) => option.id === props.entry.size_selected_id)?.name || String(props.entry.size_value ?? 'Не задан')}
                    onSelected={(value) => props.act('set_customizer_size_choice', {
                      customizer: props.entry.id,
                      var_name: props.entry.size_var_name,
                      value,
                    })}
                  />
                </Stack.Item>
              </Stack>
            </Box>
          ) : (
            <CompactRow
              label={props.entry.size_label || 'Размер'}
              value={props.entry.size_value ?? 'Не задан'}
              onClick={() => props.act('edit_customizer_size', {
                customizer: props.entry.id,
                var_name: props.entry.size_var_name,
              })}
            />
          )}
        </Box>
      ) : null}
    </Box>
  );
};

const AppearanceTab = (props: {
  data: Data;
  onEditPreference: (preference: string) => void;
  onOpenFeature: (customizer: string) => void;
  act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const simpleEntries = useMemo(() => props.data.genital_customizers || [], [props.data.genital_customizers]);
  const bodyContextEntries = useMemo(() => props.data.body_context_customizers || [], [props.data.body_context_customizers]);
  const hairCustomizer = props.data.hair_customizer;
  const facialHairCustomizer = props.data.facial_hair_customizer;

  const taurDisabled = !props.data.appearance.taur_type || props.data.appearance.taur_type === 'Нет' || props.data.appearance.taur_type === 'None';
  const bodyEntryMatcher = /ниж|бель|underwear|bra|pant|sock|stocking|чул|нос(ки|ок)|wing|крыл|tail|хвост|soul|душ/i;
  const bodyEntries = bodyContextEntries.filter((entry) => bodyEntryMatcher.test(entry.name));
  const faceEntries = bodyContextEntries.filter((entry) => !bodyEntryMatcher.test(entry.name));

  return (
    <Stack fill>
      <Stack.Item basis="58%">
        <Stack vertical fill>
          <Stack.Item basis="55%">
            <Section title="Лицо и волосы" fill scrollable>
              <CompactRow label="Цвет глаз" value={props.data.appearance.eye_color} colorPreview={props.data.appearance.eye_color} onClick={() => props.onEditPreference('eyes')} />
              <CompactRow label="Причёска" value={hairCustomizer?.current_accessory_name || 'Нет'} onClick={hairCustomizer?.id ? () => props.onOpenFeature(hairCustomizer.id) : undefined} />
              <CompactRow label="Борода" value={facialHairCustomizer?.current_accessory_name || 'Нет'} onClick={facialHairCustomizer?.id ? () => props.onOpenFeature(facialHairCustomizer.id) : undefined} />
              {faceEntries.length ? faceEntries.map((entry) => (
                <ContextCustomizerRow key={entry.id} entry={entry} act={props.act} />
              )) : (
                <Box color="label">Для этой расы нет дополнительных внешних настроек.</Box>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Тело" fill scrollable>
              <SliderNumberRow
                label="Размер персонажа"
                value={Number(props.data.appearance.body_size || 100)}
                min={props.data.appearance.body_size_min || 50}
                max={props.data.appearance.body_size_max || 150}
                step={1}
                onCommit={(value) => props.act('set_body_size_value', { value })}
              />
              <ContextDropdownRow
                label="Цвет кожи"
                selector={props.data.context_selectors?.skin_tone}
                onSelected={(value) => props.act('set_context_preference', { kind: 'skin_tone', value })}
              />
              {(props.data.appearance.taur_available || props.data.appearance.taur_type !== 'Нет') ? (
                <ContextDropdownRow
                  label="Таур-тело"
                  selector={props.data.context_selectors?.taur_type}
                  onSelected={(value) => props.act('set_context_preference', { kind: 'taur_type', value })}
                  auxButton={(
                    <PaletteButton
                      color={props.data.appearance.taur_color}
                      disabled={taurDisabled}
                      onClick={() => props.onEditPreference('taur_color')}
                    />
                  )}
                />
              ) : null}
              {bodyEntries.map((entry) => (
                <ContextCustomizerRow key={entry.id} entry={entry} act={props.act} />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Гениталии и пирсинг" fill scrollable>
          {simpleEntries.length ? simpleEntries.map((entry) => (
            <ContextCustomizerRow key={entry.id} entry={entry} act={props.act} />
          )) : (
            <Box color="label">Для этой расы нет дополнительных телесных настроек.</Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const MarkingsTab = (props: {
  data: Data;
  act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
    const [activeZone, setActiveZone] = useState<string>('');

  const zones = useMemo(
    () => props.data.body_markings || [],
    [props.data.body_markings],
  );

  const activeCatalog = useMemo(
    () => (props.data.body_marking_catalog || []).find((entry) => entry.zone === activeZone),
    [props.data.body_marking_catalog, activeZone],
  );

  useEffect(() => {
    if (!activeZone && zones.length) {
      setActiveZone(zones[0].zone);
    }
    if (activeZone && !zones.find((zone) => zone.zone === activeZone) && zones.length) {
      setActiveZone(zones[0].zone);
    }
  }, [activeZone, zones]);

  return (
    <Stack fill>
      <Stack.Item basis="48%">
        <Section title="Зоны" fill scrollable>
          {zones.length ? zones.map((zone) => (
            <Box key={zone.zone} mb={0.5} p={0.6} style={cardStyle}>
              <Stack align="center" mb={0.4}>
                <Stack.Item grow>
                  <Box bold>{zone.label}</Box>
                  <Box color="label">{zone.count ? `${zone.count} выбрано` : 'Пусто'}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button compact onClick={() => setActiveZone(zone.zone)}>Добавить</Button>
                </Stack.Item>
                <Stack.Item>
                  <Button compact disabled={!zone.count} onClick={() => props.act('clear_body_marking_zone', { zone: zone.zone })}>Очистить</Button>
                </Stack.Item>
              </Stack>
              {zone.names.length ? zone.names.map((name) => (
                <Box key={`${zone.zone}-${name}`} mb={0.3} p={0.35} style={cardStyle}>
                  <Stack align="center">
                    <Stack.Item grow>{name}</Stack.Item>
                    <Stack.Item>
                      <Button compact onClick={() => props.act('remove_body_marking', { zone: zone.zone, name })}>Убрать</Button>
                    </Stack.Item>
                  </Stack>
                </Box>
              )) : (
                <Box color="label">На этой зоне ничего нет.</Box>
              )}
            </Box>
          )) : (
            <Box color="label">Маркинги не найдены.</Box>
          )}
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section title={activeCatalog ? `Добавить: ${activeCatalog.label}` : 'Добавление'} fill scrollable>
          {!activeCatalog ? (
            <Box color="label">Выбери зону слева, чтобы добавить маркинг.</Box>
          ) : activeCatalog.options?.length ? (
            <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '8px' }}>
              {activeCatalog.options.map((option) => (
                <Button
                  key={`${activeCatalog.zone}-${option.name}`}
                  textAlign="left"
                  style={{ minHeight: '34px' }}
                  onClick={() => props.act('add_body_marking', { zone: activeCatalog.zone, name: option.name })}
                >
                  {option.name}
                </Button>
              ))}
            </Box>
          ) : (
            <Box color="label">Для этой зоны список маркингов не найден.</Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const VillainColorRow = (props: {
  label: string;
  value?: string | null;
  onEdit: () => void;
  onClear: () => void;
}) => (
  <Box mb={0.35}>
    <Stack align="center">
      <Stack.Item grow>
        <Button fluid textAlign="left" onClick={props.onEdit}>
          <Stack align="center">
            <Stack.Item basis="180px" shrink={0}>
              <Box color="label">{props.label}</Box>
            </Stack.Item>
            <Stack.Item grow>
              <Box bold>
                {props.value || 'Не задано'}
                {swatch(props.value)}
              </Box>
            </Stack.Item>
          </Stack>
        </Button>
      </Stack.Item>
      {props.value ? (
        <Stack.Item>
          <Button compact onClick={props.onClear}>Очистить</Button>
        </Stack.Item>
      ) : null}
    </Stack>
  </Box>
);

const AntagsTab = (props: {
  data: Data;
  act: (action: string, payload?: Record<string, unknown>) => void;
  onEditTextField: (field: string) => void;
}) => (
  <Stack fill>
    <Stack.Item basis="56%">
      <Section title="Предпочтения антагонистов" fill scrollable>
        <Subhead>Доступные роли</Subhead>
        <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '8px' }}>
          {(props.data.antag_roles || []).map((role) => (
            <Box
              key={role.id}
              p={0.65}
              style={role.enabled ? selectedCardStyle : cardStyle}
            >
              <Box bold mb={0.25}>{role.name}</Box>
              <Box color="label" mb={0.5}>
                {role.disabled_reason || (role.enabled ? 'Включено' : 'Выключено')}
              </Box>
              <Button
                fluid
                selected={role.enabled}
                disabled={!!role.disabled_reason}
                onClick={() => props.act('toggle_antag_role', { role: role.id })}
              >
                {role.enabled ? 'Отключить' : 'Включить'}
              </Button>
            </Box>
          ))}
        </Box>
        {!(props.data.antag_roles || []).length ? (
          <Box color="label">Список ролей не загрузился.</Box>
        ) : null}
      </Section>
    </Stack.Item>
    <Stack.Item grow>
      <Section title="Настройки злодеев" fill scrollable>
        <Subhead>Портреты</Subhead>
        <CompactRow
          wrap
          label="Lich headshot"
          value={truncate(props.data.villain_settings?.lich_headshot_link || 'Не задан', 72)}
          onClick={() => props.onEditTextField('lich_headshot_link')}
        />
        <CompactRow
          wrap
          label="Vampire headshot"
          value={truncate(props.data.villain_settings?.vampire_headshot_link || 'Не задан', 72)}
          onClick={() => props.onEditTextField('vampire_headshot_link')}
        />

        <Subhead>Цветовые пресеты</Subhead>
        <VillainColorRow
          label="Кожа вампира"
          value={props.data.villain_settings?.vampire_skin}
          onEdit={() => props.act('edit_villain_color', { pref: 'vampire_skin' })}
          onClear={() => props.act('clear_villain_color', { pref: 'vampire_skin' })}
        />
        <VillainColorRow
          label="Глаза вампира"
          value={props.data.villain_settings?.vampire_eyes}
          onEdit={() => props.act('edit_villain_color', { pref: 'vampire_eyes' })}
          onClear={() => props.act('clear_villain_color', { pref: 'vampire_eyes' })}
        />
        <VillainColorRow
          label="Волосы вампира"
          value={props.data.villain_settings?.vampire_hair}
          onEdit={() => props.act('edit_villain_color', { pref: 'vampire_hair' })}
          onClear={() => props.act('clear_villain_color', { pref: 'vampire_hair' })}
        />
        <VillainColorRow
          label="Уши вампира"
          value={props.data.villain_settings?.vampire_ears}
          onEdit={() => props.act('edit_villain_color', { pref: 'vampire_ears' })}
          onClear={() => props.act('clear_villain_color', { pref: 'vampire_ears' })}
        />

        <Subhead>Прочее</Subhead>
        <CompactRow
          label="Устойчивость к quicksilver"
          value={props.data.villain_settings?.qsr_pref ? 'Да' : 'Нет'}
          onClick={() => props.act('toggle_system_pref', { pref: 'qsr_pref' })}
        />
      </Section>
    </Stack.Item>
  </Stack>
);

const SystemTab = (props: {
  data: Data;
  act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const settings = props.data.system_settings || {};
  return (
    <Stack fill>
      <Stack.Item basis="52%">
        <Section title="Интерфейс и отображение" fill scrollable>
          <Subhead>Экран</Subhead>
          <CompactRow
            label="Тема TGUI"
            value={settings.tgui_theme_name || 'Default'}
            onClick={() => props.act('edit_system_pref', { pref: 'tgui_theme' })}
          />
          <CompactRow
            label="Мониторы TGUI"
            value={settings.tgui_lock ? 'Primary' : 'All'}
            onClick={() => props.act('toggle_system_pref', { pref: 'tgui_lock' })}
          />
          <CompactRow
            label="Ambient Occlusion"
            value={settings.ambientocclusion ? 'Включено' : 'Выключено'}
            onClick={() => props.act('toggle_system_pref', { pref: 'ambientocclusion' })}
          />
          <CompactRow
            label="Мигание окна"
            value={settings.windowflashing ? 'Включено' : 'Выключено'}
            onClick={() => props.act('toggle_system_pref', { pref: 'windowflashing' })}
          />
          <CompactRow
            label="FPS"
            value={settings.clientfps ?? 0}
            onClick={() => props.act('edit_system_pref', { pref: 'clientfps' })}
          />
          <CompactRow
            label="Подгон viewport"
            value={settings.auto_fit_viewport ? 'Авто' : 'Ручной'}
            onClick={() => props.act('toggle_system_pref', { pref: 'auto_fit_viewport' })}
          />
          <CompactRow
            label="Широкий экран"
            value={settings.widescreenpref ? 'Включён' : 'Выключен'}
            onClick={() => props.act('toggle_system_pref', { pref: 'widescreenpref' })}
          />

          <Subhead>Руны и чат</Subhead>
          <CompactRow
            label="Чат на карте"
            value={settings.chat_on_map ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'chat_on_map' })}
          />
          <CompactRow
            label="Показывать чат без моба"
            value={settings.see_chat_non_mob ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'see_chat_non_mob' })}
          />
          <CompactRow
            label="Фиксировать action buttons"
            value={settings.buttons_locked ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'buttons_locked' })}
          />
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Комфорт и текст" fill scrollable>
          <Subhead>Examine и приватность</Subhead>
          <CompactRow
            label="Тема examine для других"
            value={settings.examine_theme_name || 'None (Use Viewer\'s)'}
            onClick={() => props.act('edit_system_pref', { pref: 'examine_theme' })}
          />
          <CompactRow
            label="Анонимизация"
            value={settings.anonymize ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'anonymize' })}
          />
          <CompactRow
            label="Masked examine"
            value={settings.masked_examine ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'masked_examine' })}
          />
          <CompactRow
            label="Полный examine"
            value={settings.full_examine ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'full_examine' })}
          />
          <CompactRow
            label="Не блокировать examine"
            value={settings.no_examine_blocks ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'no_examine_blocks' })}
          />

          <Subhead>Текст и эффекты</Subhead>
          <CompactRow
            label="Быть ментором"
            value={settings.schizo_voice ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'schizo_voice' })}
          />
          <CompactRow
            label="Автопунктуация"
            value={settings.no_autopunctuate ? 'Выключена' : 'Включена'}
            onClick={() => props.act('toggle_system_pref', { pref: 'no_autopunctuate' })}
          />
          <CompactRow
            label="Шрифты языков"
            value={settings.no_language_fonts ? 'Скрыты' : 'Показываются'}
            onClick={() => props.act('toggle_system_pref', { pref: 'no_language_fonts' })}
          />
          <CompactRow
            label="Иконка языка"
            value={settings.no_language_icon ? 'Скрыта' : 'Показывается'}
            onClick={() => props.act('toggle_system_pref', { pref: 'no_language_icon' })}
          />
          <CompactRow
            label="Красная вспышка"
            value={settings.no_redflash ? 'Выключена' : 'Включена'}
            onClick={() => props.act('toggle_system_pref', { pref: 'no_redflash' })}
          />
          <CompactRow
            label="Mute animal emotes"
            value={settings.mute_animal_emotes ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'mute_animal_emotes' })}
          />
          <CompactRow
            label="Autoconsume"
            value={settings.autoconsume ? 'Да' : 'Нет'}
            onClick={() => props.act('toggle_system_pref', { pref: 'autoconsume' })}
          />

          {settings.is_admin ? (
            <>
              <Subhead>Администратор</Subhead>
              <CompactRow
                label="Play Admin MIDIs"
                value={settings.play_admin_midis ? 'Включено' : 'Выключено'}
                onClick={() => props.act('toggle_system_pref', { pref: 'hear_midis' })}
              />
              <CompactRow
                label="Adminhelp sounds"
                value={settings.hear_adminhelps ? 'Включено' : 'Выключено'}
                onClick={() => props.act('toggle_system_pref', { pref: 'hear_adminhelps' })}
              />
              {settings.can_edit_asaycolor ? (
                <CompactRow
                  label="ASAY цвет"
                  value={settings.asaycolor || '#ff4500'}
                  colorPreview={settings.asaycolor || '#ff4500'}
                  onClick={() => props.act('edit_system_pref', { pref: 'asaycolor' })}
                />
              ) : null}
              <CompactRow
                label="Always deadmin"
                value={settings.deadmin_always_forced ? 'Принудительно' : settings.deadmin_always ? 'Включено' : 'Выключено'}
                onClick={settings.deadmin_always_forced ? undefined : () => props.act('toggle_system_pref', { pref: 'toggle_deadmin_always' })}
              />
              <CompactRow
                label="Deadmin as antag"
                value={settings.deadmin_antag_forced ? 'Принудительно' : settings.deadmin_antag ? 'Deadmin' : 'Keep Admin'}
                onClick={settings.deadmin_antag_forced ? undefined : () => props.act('toggle_system_pref', { pref: 'toggle_deadmin_antag' })}
              />
              <CompactRow
                label="Deadmin as command"
                value={settings.deadmin_head_forced ? 'Принудительно' : settings.deadmin_head ? 'Deadmin' : 'Keep Admin'}
                onClick={settings.deadmin_head_forced ? undefined : () => props.act('toggle_system_pref', { pref: 'toggle_deadmin_head' })}
              />
            </>
          ) : null}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const KeyCaptureModal = (props: {
  bindingLabel: string;
  oldKey?: string | null;
  onClose: () => void;
  onSet: (payload: {
    key: string;
    alt: boolean;
    ctrl: boolean;
    shift: boolean;
    numpad: boolean;
  }) => void;
  onClear: () => void;
}) => {
  const captureRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    captureRef.current?.focus();
  }, []);

  const onKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    event.preventDefault();
    event.stopPropagation();

    if (event.key === 'Escape') {
      props.onClose();
      return;
    }

    props.onSet({
      key: event.key,
      alt: event.altKey,
      ctrl: event.ctrlKey,
      shift: event.shiftKey,
      numpad: event.location === 3,
    });
  };

  return (
    <ModalShell title={`Назначение клавиши: ${props.bindingLabel}`} width="520px" onClose={props.onClose}>
      <div
        ref={captureRef}
        tabIndex={0}
        style={{
          ...cardStyle,
          outline: 'none',
          minHeight: '140px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          lineHeight: 1.4,
          padding: '1.2rem',
        }}
        onKeyDown={onKeyDown}
      >
        <div>
          Нажми нужную клавишу или сочетание.
          <br />
          Escape — закрыть.
        </div>
      </div>
      <Stack mt={0.75}>
        <Stack.Item grow>
          <Button fluid onClick={props.onClose}>Отмена</Button>
        </Stack.Item>
        {props.oldKey ? (
          <Stack.Item grow>
            <Button fluid color="bad" onClick={props.onClear}>Очистить</Button>
          </Stack.Item>
        ) : null}
      </Stack>
    </ModalShell>
  );
};

const KeysTab = (props: {
  data: Data;
  onCapture: (binding: KeybindEntry, oldKey?: string | null) => void;
  onResetDefaults: () => void;
}) => (
  <Section title="Клавиши" fill scrollable>
    <Stack mb={0.6} align="center">
      <Stack.Item grow>
        <Box color="label">Активный пресет: <b>{props.data.keybind_mode || 'Hotkey'}</b></Box>
      </Stack.Item>
      <Stack.Item>
        <Button onClick={props.onResetDefaults}>Сбросить к дефолту</Button>
      </Stack.Item>
    </Stack>

    {(props.data.keybinding_categories || []).map((category) => (
      <Box key={category.name} mb={0.8}>
        <Subhead>{category.name}</Subhead>
        {category.bindings.map((binding) => (
          <Box key={binding.id} mb={0.35} p={0.55} style={cardStyle}>
            <Stack align="center">
              <Stack.Item grow>
                <Box style={{ overflowWrap: 'anywhere' }}>{binding.label}</Box>
              </Stack.Item>
              <Stack.Item>
                <Stack>
                  {binding.keys.length ? binding.keys.map((key) => (
                    <Stack.Item key={`${binding.id}-${key}`}>
                      <Button compact onClick={() => props.onCapture(binding, key)}>{key}</Button>
                    </Stack.Item>
                  )) : (
                    <Stack.Item>
                      <Button compact onClick={() => props.onCapture(binding, null)}>Не назначено</Button>
                    </Stack.Item>
                  )}
                  <Stack.Item>
                    <Button compact onClick={() => props.onCapture(binding, null)}>+</Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Box>
        ))}
      </Box>
    ))}
  </Section>
);


export const CharacterSetup = () => {
  const { act, data } = useBackend<Data>();
  const [mainTab, setMainTab] = useState<MainTab>('general');
  const [dialog, setDialog] = useState<DialogTab>(null);
  const [keyCapture, setKeyCapture] = useState<{ binding: KeybindEntry; oldKey?: string | null } | null>(null);
  const [featureTargetId, setFeatureTargetId] = useState<string | null>(null);
  const [previewRotatePending, setPreviewRotatePending] = useState(false);
  const lastPreviewDirectionRef = useRef(data.preview_direction);
  const activeCustomizer = data.active_customizer && (!featureTargetId || data.active_customizer.id === featureTargetId)
    ? data.active_customizer
    : null;

  useEffect(() => {
    if (data.preview_direction !== lastPreviewDirectionRef.current) {
      lastPreviewDirectionRef.current = data.preview_direction;
      setPreviewRotatePending(false);
    }
  }, [data.preview_direction]);

  const handleEditPreference = (preference: string) => act('edit_preference', { preference });
  const handleEditTextField = (field: string) => act('edit_text_field', { field });
  const handleOpenFeature = (customizer: string) => {
    setFeatureTargetId(customizer);
    act('select_customizer', { customizer });
    setDialog('feature');
  };

  const handleRotatePreview = (step: number) => {
    if (previewRotatePending) {
      return;
    }
    setPreviewRotatePending(true);
    act('rotate_preview', { step });
  };

  return (
    <Window title="Настройка персонажа" width={1440} height={860}>
      <Window.Content>
        <Box style={{ position: 'relative', height: '100%' }}>
          {dialog === 'slots' ? (
            <SlotModal
              slots={data.slot_summaries || []}
              onSelect={(slot) => {
                act('load_slot', { slot });
                setDialog(null);
              }}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {dialog === 'feature' ? (
            <FeatureModal
              data={data}
              active={activeCustomizer}
              act={act}
              onClose={() => { setFeatureTargetId(null); setDialog(null); }}
            />
          ) : null}
          {dialog === 'gender' ? (
            <GenderModal
              data={data}
              onApplyPreset={(preset) => act('apply_gender_preset', { preset })}
              onSetBodyType={(gender) => act('set_gender_body_type', { gender })}
              onSetVoiceType={(voiceType) => act('set_voice_identity', { voice_type: voiceType })}
              onEditPreference={handleEditPreference}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {dialog === 'vices' ? (
            <VicesModal
              options={data.vice_options || []}
              limit={data.vice_limit}
              act={act}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {dialog === 'descriptors' ? (
            <DescriptorsModal
              data={data.descriptor_editor}
              act={act}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {dialog === 'culinary' ? (
            <CulinaryModal
              data={data.culinary_editor}
              act={act}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {dialog === 'familiar' ? (
            <FamiliarModal
              data={data.familiar_editor}
              act={act}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {dialog === 'combat_music' ? (
            <SearchableSelectorModal
              title="Боевая музыка"
              selector={data.context_selectors?.combat_music}
              onSelected={(value) => {
                act('set_context_preference', { kind: 'combat_music', value });
                setDialog(null);
              }}
              onClose={() => setDialog(null)}
            />
          ) : null}
          {keyCapture ? (
            <KeyCaptureModal
              bindingLabel={keyCapture.binding.label}
              oldKey={keyCapture.oldKey}
              onClose={() => setKeyCapture(null)}
              onClear={() => {
                act('set_keybinding', {
                  keybinding: keyCapture.binding.id,
                  old_key: keyCapture.oldKey || undefined,
                  clear_key: 1,
                });
                setKeyCapture(null);
              }}
              onSet={(payload) => {
                act('set_keybinding', {
                  keybinding: keyCapture.binding.id,
                  old_key: keyCapture.oldKey || undefined,
                  clear_key: 0,
                  key: payload.key,
                  alt: payload.alt ? 1 : 0,
                  ctrl: payload.ctrl ? 1 : 0,
                  shift: payload.shift ? 1 : 0,
                  numpad: payload.numpad ? 1 : 0,
                });
                setKeyCapture(null);
              }}
            />
          ) : null}

          <Stack fill>
            <Stack.Item basis="430px" shrink={0}>
              <LeftPane
                data={data}
                onRotate={handleRotatePreview}
                rotatePending={previewRotatePending}
                onOpenPlayerQuality={() => act('open_player_quality')}
                onOpenTriumphs={() => act('open_triumphs')}
                onPreviewFlavor={() => act('preview_flavor')}
                onEditPreference={handleEditPreference}
                onOpenGenderMenu={() => setDialog('gender')}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Stack vertical fill>
                <Stack.Item>
                  <Section
                    title="Действия"
                    fitted
                    buttons={(
                      <>
                        <Button icon="undo" onClick={() => act('undo_setup')}>Откатить</Button>
                        <Button icon="save" onClick={() => act('save_setup')}>Сохранить</Button>
                        <Button icon="user" onClick={() => setDialog('slots')}>Сменить слот</Button>
                        <Button icon="briefcase" onClick={() => act('open_jobs_window')}>Выбор класса</Button>
                        <Button icon="suitcase" onClick={() => act('open_loadout')}>Лодаут</Button>
                        <Button icon="check" onClick={() => act('done_setup')}>Готово</Button>
                      </>
                    )}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Tabs>
                    <Tabs.Tab selected={mainTab === 'general'} onClick={() => setMainTab('general')}>Общее</Tabs.Tab>
                    <Tabs.Tab selected={mainTab === 'appearance'} onClick={() => setMainTab('appearance')}>Внешность</Tabs.Tab>
                    <Tabs.Tab selected={mainTab === 'markings'} onClick={() => setMainTab('markings')}>Маркинги</Tabs.Tab>
                    <Tabs.Tab selected={mainTab === 'notes'} onClick={() => setMainTab('notes')}>Заметки</Tabs.Tab>
                    <Tabs.Tab selected={mainTab === 'antags'} onClick={() => setMainTab('antags')}>Антагонисты</Tabs.Tab>
                    <Tabs.Tab selected={mainTab === 'system'} onClick={() => setMainTab('system')}>Система</Tabs.Tab>
                    <Tabs.Tab selected={mainTab === 'keys'} onClick={() => setMainTab('keys')}>Клавиши</Tabs.Tab>
                  </Tabs>
                </Stack.Item>
                <Stack.Item grow>
                  {mainTab === 'general' ? (
                    <GeneralTab
                      data={data}
                      onEditPreference={handleEditPreference}
                      onManageVices={() => setDialog('vices')}
                      onOpenDescriptors={() => setDialog('descriptors')}
                      onOpenCulinary={() => setDialog('culinary')}
                      onOpenFamiliar={() => setDialog('familiar')}
                      onOpenCombatMusic={() => setDialog('combat_music')}
                      act={act}
                    />
                  ) : mainTab === 'appearance' ? (
                    <AppearanceTab
                      data={data}
                      onEditPreference={handleEditPreference}
                      onOpenFeature={handleOpenFeature}
                      act={act}
                    />
                  ) : mainTab === 'markings' ? (
                    <MarkingsTab
                      data={data}
                      act={act}
                    />
                  ) : mainTab === 'notes' ? (
                    <NotesTab
                      data={data}
                      onEditPreference={handleEditPreference}
                      onEditTextField={handleEditTextField}
                      act={act}
                    />
                  ) : mainTab === 'antags' ? (
                    <AntagsTab
                      data={data}
                      act={act}
                      onEditTextField={handleEditTextField}
                    />
                  ) : mainTab === 'system' ? (
                    <SystemTab
                      data={data}
                      act={act}
                    />
                  ) : (
                    <KeysTab
                      data={data}
                      onCapture={(binding, oldKey) => setKeyCapture({ binding, oldKey })}
                      onResetDefaults={() => act('reset_keybindings')}
                    />
                  )}
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};
