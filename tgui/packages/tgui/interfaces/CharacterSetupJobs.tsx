
import { type ReactNode, useEffect, useMemo, useState } from 'react';
import { Box, Button, Stack, Tooltip } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type JobEntry = {
  id: string;
  name: string;
  current_pref: 'never' | 'low' | 'medium' | 'high' | string;
  disabled_reason?: string | null;
  assigned_slot?: string;
  column?: number;
  separator_before?: boolean;
  tutorial?: string;
  slots?: number;
  round_contrib_points?: number;
  has_details?: boolean;
  tooltip?: string;
};

type JobSlotChoice = {
  id: string;
  label: string;
  current: boolean;
};

type StatRow = {
  name: string;
  value: string;
  positive?: boolean;
};

type TraitRow = {
  name: string;
  description?: string;
};

type JobSubclassDetail = {
  id: string;
  name: string;
  description?: string;
  stat_bonuses?: StatRow[];
  stat_limits?: StatRow[];
  traits?: TraitRow[];
  notable_skills?: string[];
  virtues?: string[];
  stashed_items?: string[];
  languages?: string[];
  mage_aspects?: string[];
  extra_context?: string[];
};

type JobDetail = {
  title: string;
  description?: string;
  class_stats?: StatRow[];
  class_stat_limits?: StatRow[];
  class_traits?: TraitRow[];
  note?: string;
  subclasses?: JobSubclassDetail[];
};

type Data = {
  job_entries: JobEntry[];
  job_slot_target?: string | null;
  job_slot_choices?: JobSlotChoice[];
  current_joblessrole?: string;
  active_job_detail?: JobDetail | null;
};

const cardStyle = {
  border: '1px solid rgba(255,255,255,0.12)',
};

const selectedCardStyle = {
  border: '1px solid rgba(255,255,255,0.32)',
  boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.08)',
};

const stripSimpleHtml = (value?: string | null) => {
  if (!value) {
    return '';
  }
  return value
    .replace(/<br\s*\/?>(?!$)/gi, '\n')
    .replace(/<\/?span[^>]*>/gi, '')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/gi, ' ')
    .trim();
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

const fillForPref = (pref?: string) => {
  switch (pref) {
    case 'high':
      return '#58b26b';
    case 'medium':
      return '#c8a24c';
    case 'low':
      return '#b65b5b';
    case 'never':
    default:
      return '#8a6a6a';
  }
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
        width: props.width || '900px',
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

const JobPriorityButton = (props: {
  active?: boolean;
  color?: string;
  onClick: () => void;
}) => (
  <Button
    circular
    compact
    onClick={props.onClick}
    style={{
      width: '23px',
      height: '23px',
      minWidth: '23px',
      minHeight: '23px',
      padding: 0,
      borderRadius: '50%',
      background: props.active ? fillForPref(props.color) : 'rgba(255,255,255,0.04)',
      border: props.active
        ? '1px solid rgba(255,255,255,0.35)'
        : '1px solid rgba(255,255,255,0.18)',
      boxShadow: props.active ? '0 0 0 1px rgba(255,255,255,0.08) inset' : undefined,
    }}
  />
);

const normalizeSlotLabel = (label?: string) => {
  if (!label) {
    return '—';
  }
  if (label === 'Активный слот' || label === 'Active' || label === 'Актив.' || label === '[Active slot]') {
    return '—';
  }
  const slotMatch = label.match(/(?:Слот|Slot)\s*(\d+)/i);
  if (slotMatch?.[1]) {
    return slotMatch[1];
  }
  return label;
};

const buildJobColumns = (entries: JobEntry[]) => {
  const columns = new Map<number, JobEntry[]>();
  entries.forEach((entry) => {
    const key = entry.column || 1;
    const current = columns.get(key) || [];
    current.push(entry);
    columns.set(key, current);
  });
  return Array.from(columns.entries())
    .sort((a, b) => a[0] - b[0])
    .map(([, value]) => value);
};

const jobNameLines = (name: string) => {
  const words = name.trim().split(/\s+/).filter(Boolean);

  if (words.length <= 1) {
    return [name];
  }
  if (words.length === 2) {
    return name.length > 12 ? words : [name];
  }
  if (words.length === 3) {
    return name.length > 16 ? [`${words[0]} ${words[1]}`, words[2]] : [name];
  }
  if (words.length === 4) {
    return [`${words[0]} ${words[1]}`, `${words[2]} ${words[3]}`];
  }
  return [name];
};

const JobSlotTag = (props: { label: string; onClick: () => void }) => (
  <Button
    compact
    fontSize={0.82}
    onClick={props.onClick}
    style={{
      width: '34px',
      minWidth: '34px',
      maxWidth: '34px',
      padding: '0 0px',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap',
    }}
  >
    {normalizeSlotLabel(props.label)}
  </Button>
);

const HEADER_NAME_WIDTH = '104px';
const PRIORITY_COL_WIDTH = '92px';
const SLOT_COL_WIDTH = '42px';
const ROW_GRID = `${HEADER_NAME_WIDTH} ${PRIORITY_COL_WIDTH} ${SLOT_COL_WIDTH}`;

const JobPriorityHeader = () => (
  <Box
    style={{
      display: 'grid',
      gridTemplateColumns: ROW_GRID,
      columnGap: '0px',
      alignItems: 'end',
      marginBottom: '1px',
      fontSize: '8.5px',
      color: 'rgba(255,255,255,0.74)',
      padding: 0,
    }}
  >
    <Box />
    <Box
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 23px)',
        columnGap: '0px',
        justifyContent: 'start',
        alignItems: 'center',
        lineHeight: 1,
      }}
    >
      <Box textAlign="center">Off</Box>
      <Box textAlign="center">Low</Box>
      <Box textAlign="center">Med</Box>
      <Box textAlign="center">High</Box>
    </Box>
    <Box textAlign="center">Слот</Box>
  </Box>
);

const JobSlotModal = (props: {
  jobTitle?: string | null;
  choices: JobSlotChoice[];
  onSelect: (slot: string) => void;
  onClose: () => void;
}) => (
  <ModalShell title={`Персонаж для роли: ${props.jobTitle || 'Роль'}`} width="840px" onClose={props.onClose}>
    {props.choices.map((choice) => (
      <Box key={choice.id} mb={0.5} p={0.75} style={choice.current ? selectedCardStyle : cardStyle}>
        <Stack align="center">
          <Stack.Item grow>
            <Box bold>{choice.label}</Box>
          </Stack.Item>
          <Stack.Item>
            <Button onClick={() => props.onSelect(choice.id)}>
              {choice.current ? 'Используется сейчас' : choice.id === 'default' ? 'Сделать активным слотом' : 'Выбрать'}
            </Button>
          </Stack.Item>
        </Stack>
      </Box>
    ))}
  </ModalShell>
);

const SectionTitle = (props: { children: ReactNode }) => (
  <Box mt={0.75} mb={0.35} bold color="label">
    {props.children}
  </Box>
);

const StatList = (props: { rows?: StatRow[] }) => {
  if (!props.rows?.length) {
    return null;
  }
  return (
    <Box>
      {props.rows.map((row) => (
        <Box key={`${row.name}-${row.value}`} style={{ lineHeight: 1.15 }}>
          {row.name}: <Box inline bold color={row.positive === false ? 'bad' : row.positive ? 'good' : undefined}>{row.value}</Box>
        </Box>
      ))}
    </Box>
  );
};

const TraitList = (props: { rows?: TraitRow[] }) => {
  if (!props.rows?.length) {
    return null;
  }
  return (
    <Box>
      {props.rows.map((row) => (
        <Box key={row.name} mb={0.3} p={0.4} style={cardStyle}>
          <Box bold>{row.name}</Box>
          {row.description ? <Box mt={0.2} color="label" style={{ whiteSpace: 'pre-wrap', lineHeight: 1.15 }}>{stripSimpleHtml(row.description)}</Box> : null}
        </Box>
      ))}
    </Box>
  );
};

const StringList = (props: { items?: string[] }) => {
  if (!props.items?.length) {
    return null;
  }
  return (
    <Box>
      {props.items.map((item, index) => (
        <Box key={`${item}-${index}`} style={{ lineHeight: 1.15 }}>
          • {stripSimpleHtml(item)}
        </Box>
      ))}
    </Box>
  );
};

const JobDetailsModal = (props: {
  detail?: JobDetail | null;
  onClose: () => void;
}) => {
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});

  useEffect(() => {
    setExpanded({});
  }, [props.detail?.title]);

  const toggle = (id: string) => setExpanded((old) => ({ ...old, [id]: !old[id] }));

  if (!props.detail) {
    return null;
  }

  return (
    <ModalShell title={props.detail.title || 'Информация о роли'} width="920px" onClose={props.onClose}>
      {props.detail.description ? (
        <Box mb={0.5} color="label" style={{ whiteSpace: 'pre-wrap', lineHeight: 1.2 }}>
          {stripSimpleHtml(props.detail.description)}
        </Box>
      ) : null}

      <Stack>
        <Stack.Item basis="50%">
          <SectionTitle>Статы</SectionTitle>
          <StatList rows={props.detail.class_stats} />
          {props.detail.class_stat_limits?.length ? (
            <>
              <SectionTitle>Пределы статов</SectionTitle>
              <StatList rows={props.detail.class_stat_limits} />
            </>
          ) : null}
        </Stack.Item>
        <Stack.Item grow>
          {props.detail.class_traits?.length ? (
            <>
              <SectionTitle>Черты класса</SectionTitle>
              <TraitList rows={props.detail.class_traits} />
            </>
          ) : null}
        </Stack.Item>
      </Stack>

      {props.detail.subclasses?.length ? (
        <>
          <SectionTitle>Сабклассы</SectionTitle>
          {props.detail.subclasses.map((subclass) => {
            const isOpen = !!expanded[subclass.id];
            return (
              <Box key={subclass.id} mb={0.45} style={cardStyle}>
                <Button
                  fluid
                  textAlign="left"
                  onClick={() => toggle(subclass.id)}
                  style={{ minHeight: '34px' }}
                >
                  {isOpen ? '▼ ' : '▶ '}{subclass.name}
                </Button>
                {isOpen ? (
                  <Box p={0.6}>
                    {subclass.description ? (
                      <Box mb={0.45} color="label" style={{ whiteSpace: 'pre-wrap', lineHeight: 1.2 }}>
                        {stripSimpleHtml(subclass.description)}
                      </Box>
                    ) : null}
                    <Stack>
                      <Stack.Item basis="50%">
                        {subclass.stat_bonuses?.length ? (
                          <>
                            <SectionTitle>Бонусы статов</SectionTitle>
                            <StatList rows={subclass.stat_bonuses} />
                          </>
                        ) : null}
                        {subclass.stat_limits?.length ? (
                          <>
                            <SectionTitle>Пределы статов</SectionTitle>
                            <StatList rows={subclass.stat_limits} />
                          </>
                        ) : null}
                        {subclass.mage_aspects?.length ? (
                          <>
                            <SectionTitle>Аспекты магии</SectionTitle>
                            <StringList items={subclass.mage_aspects} />
                          </>
                        ) : null}
                        {subclass.languages?.length ? (
                          <>
                            <SectionTitle>Языки</SectionTitle>
                            <StringList items={subclass.languages} />
                          </>
                        ) : null}
                      </Stack.Item>
                      <Stack.Item grow>
                        {subclass.traits?.length ? (
                          <>
                            <SectionTitle>Черты</SectionTitle>
                            <TraitList rows={subclass.traits} />
                          </>
                        ) : null}
                        {subclass.notable_skills?.length ? (
                          <>
                            <SectionTitle>Заметные навыки</SectionTitle>
                            <StringList items={subclass.notable_skills} />
                          </>
                        ) : null}
                        {subclass.virtues?.length ? (
                          <>
                            <SectionTitle>Добродетели</SectionTitle>
                            <StringList items={subclass.virtues} />
                          </>
                        ) : null}
                        {subclass.stashed_items?.length ? (
                          <>
                            <SectionTitle>Тайники</SectionTitle>
                            <StringList items={subclass.stashed_items} />
                          </>
                        ) : null}
                        {subclass.extra_context?.length ? (
                          <>
                            <SectionTitle>Дополнительно</SectionTitle>
                            <StringList items={subclass.extra_context} />
                          </>
                        ) : null}
                      </Stack.Item>
                    </Stack>
                  </Box>
                ) : null}
              </Box>
            );
          })}
        </>
      ) : null}

      {props.detail.note ? (
        <Box mt={0.75} color="label" style={{ whiteSpace: 'pre-wrap', lineHeight: 1.15 }}>
          {props.detail.note}
        </Box>
      ) : null}
    </ModalShell>
  );
};

export const CharacterSetupJobs = () => {
  const { act, data } = useBackend<Data>();
  const [slotOpen, setSlotOpen] = useState(false);
  const columns = useMemo(() => buildJobColumns(data.job_entries || []), [data.job_entries]);

  return (
    <Window title="Выбор класса" width={1211} height={585}>
      <Window.Content scrollable={false}>
        <Box style={{ position: 'relative', height: '100%' }}>
          {slotOpen ? (
            <JobSlotModal
              jobTitle={data.job_slot_target}
              choices={data.job_slot_choices || []}
              onSelect={(slot) => {
                act('assign_job_slot', { slot });
                setSlotOpen(false);
              }}
              onClose={() => setSlotOpen(false)}
            />
          ) : null}
          {data.active_job_detail ? (
            <JobDetailsModal
              detail={data.active_job_detail}
              onClose={() => act('close_job_details')}
            />
          ) : null}
          <Box textAlign="center" mb={0.2}>
            <Button onClick={() => act('reset_jobs')}>Сброс</Button>
            <Box mt={0.2} color="label">Нажми на незаблокированную роль, чтобы сменить приоритет.</Box>
            <Box mt={0.1}>
              <Button compact onClick={() => act('cycle_joblessrole')}>
                Если роль недоступна: {data.current_joblessrole || 'Return to Lobby'}
              </Button>
            </Box>
          </Box>
          <Box style={{ height: 'calc(100% - 46px)', overflowX: 'auto', overflowY: 'auto', paddingBottom: '2px' }}>
            <Box
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, 236px)',
                gap: '3px',
                minWidth: `${Math.max(columns.length, 1) * 238}px`,
                width: 'max-content',
                margin: '0 auto',
                justifyContent: 'center',
                paddingBottom: '8px',
              }}
            >
              {columns.map((column, index) => (
                <Box
                  key={index}
                  p={0}
                  style={{
                    border: '1px solid rgba(255,255,255,0.12)',
                    background: 'rgba(255,255,255,0.02)',
                  }}
                >
                  <JobPriorityHeader />
                  {column.map((entry) => (
                    <Box key={entry.id} mb={0.03}>
                      {entry.separator_before ? (
                        <Box my={0.14}>
                          <hr style={{ borderColor: 'rgba(255,255,255,0.25)' }} />
                        </Box>
                      ) : null}
                      <Box
                        style={{
                          display: 'grid',
                          gridTemplateColumns: ROW_GRID,
                          columnGap: '0px',
                          alignItems: 'center',
                          minHeight: '27px',
                        }}
                      >
                        <Tooltip
                          content={
                            <Box style={{ whiteSpace: 'pre-wrap', maxWidth: '360px', lineHeight: 1.2 }}>
                              {stripSimpleHtml(entry.tooltip || 'Нет описания.')}
                            </Box>
                          }
                          position="bottom-start"
                        >
                          <Box
                            onClick={entry.has_details ? () => act('open_job_details', { job: entry.id }) : undefined}
                            style={{
                              lineHeight: 0.92,
                              paddingLeft: '0px',
                              paddingRight: '3px',
                              fontSize: '16px',
                              fontWeight: 700,
                              textAlign: 'right',
                              whiteSpace: 'normal',
                              wordBreak: 'normal',
                              overflowWrap: 'normal',
                              cursor: entry.has_details ? 'pointer' : 'default',
                            }}
                          >
                            {jobNameLines(entry.name).map((line, lineIndex) => (
                              <Box key={`${entry.id}-${lineIndex}`}>{line}</Box>
                            ))}
                          </Box>
                        </Tooltip>
                        {entry.disabled_reason ? (
                          <Box
                            color="bad"
                            bold
                            style={{
                              whiteSpace: 'normal',
                              lineHeight: 0.82,
                              fontSize: '11.5px',
                              textAlign: 'center',
                            }}
                          >
                            {entry.disabled_reason}
                          </Box>
                        ) : (
                          <Box
                            style={{
                              display: 'grid',
                              gridTemplateColumns: 'repeat(4, 23px)',
                              gap: '0px',
                              alignItems: 'center',
                              justifyItems: 'center',
                            }}
                          >
                            <JobPriorityButton active={entry.current_pref === 'never'} color="never" onClick={() => act('set_job_pref', { job: entry.id, level: 'never' })} />
                            <JobPriorityButton active={entry.current_pref === 'low'} color="low" onClick={() => act('set_job_pref', { job: entry.id, level: 'low' })} />
                            <JobPriorityButton active={entry.current_pref === 'medium'} color="medium" onClick={() => act('set_job_pref', { job: entry.id, level: 'medium' })} />
                            <JobPriorityButton active={entry.current_pref === 'high'} color="high" onClick={() => act('set_job_pref', { job: entry.id, level: 'high' })} />
                          </Box>
                        )}
                        <Box textAlign="center" style={{ paddingRight: '0px', paddingLeft: '0px' }}>
                          <JobSlotTag
                            label={entry.assigned_slot || '—'}
                            onClick={() => {
                              act('open_job_slot', { job: entry.id });
                              setSlotOpen(true);
                            }}
                          />
                        </Box>
                      </Box>
                    </Box>
                  ))}
                </Box>
              ))}
            </Box>
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};
