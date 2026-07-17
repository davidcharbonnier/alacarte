import { useEffect, useMemo, useState } from 'react';
import {
  DataGrid,
  type GridColDef,
  type GridPaginationModel,
  type GridSortModel,
} from '@mui/x-data-grid';
import { Box, Chip, IconButton, InputAdornment, Stack, TextField, Tooltip, Typography } from '@mui/material';
import Visibility from '@mui/icons-material/Visibility';
import Delete from '@mui/icons-material/Delete';
import Image from '@mui/icons-material/Image';
import Inventory2 from '@mui/icons-material/Inventory2';
import Search from '@mui/icons-material/Search';
import { useQuery } from '@tanstack/react-query';
import { Link } from '@tanstack/react-router';
import { useSchema } from '../../lib/context/schema-context';
import { dynamicItemApi } from '../../lib/api/schema-api';
import { resolveIcon } from '../../lib/icons/icon-registry';
import { getAccentColor } from '../../theme';
import type { SchemaField } from '../../lib/types/schema';

const PAGE_SIZE = 20;

function getFieldValue(item: any, fieldKey: string): any {
  if (fieldKey === 'image_url') return item.image_url;
  if (fieldKey === 'id') return item.id;
  if (fieldKey === 'name') return item.name ?? item.field_values?.name;
  return item.field_values?.[fieldKey];
}

function formatCellValue(field: SchemaField | undefined, value: any) {
  if (value === null || value === undefined || value === '') {
    if (field?.field_type === 'checkbox') return '—';
    return '—';
  }
  if (field?.field_type === 'checkbox') return value ? 'Yes' : 'No';
  if (field?.field_type === 'select' || field?.field_type === 'enum') {
    const option = field.options?.find((o) => o.value === value);
    return option?.label || value;
  }
  return value.toString();
}

export function GenericItemTable({ itemType }: { itemType: string }) {
  const { schema, fields, isLoading: schemaLoading } = useSchema(itemType);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [pagination, setPagination] = useState<GridPaginationModel>({ page: 0, pageSize: PAGE_SIZE });
  const [hasImageFilter, setHasImageFilter] = useState<boolean | undefined>(undefined);
  const [sortModel, setSortModel] = useState<GridSortModel>([{ field: 'name', sort: 'asc' }]);

  // Debounce search → reset to page 0 when the debounced value changes.
  useEffect(() => {
    const id = setTimeout(() => {
      setDebouncedSearch(search);
      setPagination((p) => ({ ...p, page: 0 }));
    }, 300);
    return () => clearTimeout(id);
  }, [search]);

  const sortParam = sortModel[0]
    ? `${sortModel[0].sort === 'desc' ? '-' : ''}${sortModel[0].field}`
    : 'name';

  const { data, isLoading: itemsLoading } = useQuery({
    queryKey: ['items', itemType, 'list', pagination.page + 1, debouncedSearch, hasImageFilter, sortParam],
    queryFn: () =>
      dynamicItemApi.list(itemType, {
        page: pagination.page + 1,
        page_size: pagination.pageSize,
        search: debouncedSearch || undefined,
        has_image: hasImageFilter,
        sort: sortParam,
      }),
    // ponytail: keep the previous page's data visible while the new page loads
    // so the DataGrid doesn't see rowCount=0 and reset pagination to page 0.
    placeholderData: (prev) => prev,
  });

  const items = data?.items || [];
  const accent = getAccentColor(schema?.color);
  const isLoading = schemaLoading || itemsLoading;

  const tableColumns = useMemo<SchemaField[]>(() => {
    const uniqueFields = schema?.unique_fields || [];
    if (uniqueFields.length > 0) {
      return fields
        .filter((f) => uniqueFields.includes(f.key))
        .sort((a, b) => uniqueFields.indexOf(a.key) - uniqueFields.indexOf(b.key))
        .slice(0, 5);
    }
    return [...fields].sort((a, b) => a.order - b.order).slice(0, 5);
  }, [schema, fields]);

  const columns: GridColDef[] = useMemo(() => {
    const fieldByKey = new Map(fields.map((f) => [f.key, f]));

    const cols: GridColDef[] = [
      {
        field: 'name',
        headerName: 'Name',
        flex: 1.2,
        minWidth: 220,
        sortable: true,
        renderCell: (params) => {
          const item = params.row;
          const itemName = getFieldValue(item, 'name') || `Item #${item.id}`;
          const Icon = resolveIcon(schema?.icon);
          return (
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ height: '100%' }}>
              {item.image_url ? (
                <Box
                  component="img"
                  src={item.image_url}
                  alt={itemName}
                  sx={{ width: 40, height: 40, borderRadius: '8px', objectFit: 'cover' }}
                />
              ) : (
                <Box
                  sx={{
                    width: 40,
                    height: 40,
                    borderRadius: '8px',
                    bgcolor: 'surfaceContainerHighest',
                    color: 'onSurfaceVariant',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <Icon sx={{ fontSize: 20 }} />
                </Box>
              )}
              <Typography variant="bodyMedium" fontWeight={500}>
                {itemName}
              </Typography>
            </Stack>
          );
        },
      },
      ...tableColumns.map<GridColDef>((field) => ({
        field: field.key,
        headerName: field.label,
        flex: 1,
        minWidth: 120,
        sortable: true,
        valueGetter: (value, row) => getFieldValue(row, field.key),
        renderCell: (params) => {
          const f = fieldByKey.get(params.field as string);
          return <Typography variant="bodyMedium">{formatCellValue(f, params.value)}</Typography>;
        },
      })),
      {
        field: 'actions',
        headerName: '',
        sortable: false,
        filterable: false,
        align: 'right',
        headerAlign: 'right',
        width: 100,
        renderCell: (params) => {
          const item = params.row;
          return (
            <Stack direction="row" spacing={0.5} alignItems="center" sx={{ height: '100%' }}>
              <Tooltip title="View">
                <IconButton component={Link} to={`/items/${itemType}/${item.id}`} size="small">
                  <Visibility fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Delete">
                <IconButton
                  component={Link}
                  to={`/items/${itemType}/${item.id}/delete`}
                  size="small"
                  color="error"
                >
                  <Delete fontSize="small" />
                </IconButton>
              </Tooltip>
            </Stack>
          );
        },
      },
    ];

    return cols;
  }, [tableColumns, fields, itemType, accent, schema]);

  return (
    <Stack spacing={2.5}>
      <Stack direction="row" spacing={1.5} alignItems="center" flexWrap="wrap" useFlexGap>
        <TextField
          size="small"
          placeholder={`Search ${schema?.plural_name?.toLowerCase() || 'items'}`}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          sx={{ minWidth: 280, flexGrow: 1, maxWidth: 480 }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search fontSize="small" />
              </InputAdornment>
            ),
          }}
        />
        <Chip
          label="Has image"
          icon={<Image />}
          onClick={() => {
            setHasImageFilter(hasImageFilter === true ? undefined : true);
            setPagination((p) => ({ ...p, page: 0 }));
          }}
          color={hasImageFilter === true ? 'primary' : 'default'}
          variant={hasImageFilter === true ? 'filled' : 'outlined'}
        />
        <Chip
          label="No image"
          icon={<Inventory2 />}
          onClick={() => {
            setHasImageFilter(hasImageFilter === false ? undefined : false);
            setPagination((p) => ({ ...p, page: 0 }));
          }}
          color={hasImageFilter === false ? 'primary' : 'default'}
          variant={hasImageFilter === false ? 'filled' : 'outlined'}
        />
      </Stack>

      <Box sx={{ height: 600, width: '100%' }}>
        <DataGrid
          rows={items}
          columns={columns}
          loading={isLoading}
          rowCount={data?.total ?? 0}
          paginationMode="server"
          sortingMode="server"
          paginationModel={pagination}
          onPaginationModelChange={setPagination}
          sortModel={sortModel}
          onSortModelChange={(m) => {
            setSortModel(m);
            setPagination((p) => ({ ...p, page: 0 }));
          }}
          pageSizeOptions={[10, 20, 50]}
          disableRowSelectionOnClick
          getRowId={(row) => row.id}
          sx={{
            border: 'none',
            bgcolor: 'transparent',
            '& .MuiDataGrid-columnHeaders': {
              bgcolor: 'surfaceContainerLow',
              borderRadius: '12px 12px 0 0',
            },
            '& .MuiDataGrid-cell': { borderColor: 'outlineVariant' },
            '& .MuiDataGrid-row:hover': { bgcolor: 'surfaceContainerLow' },
          }}
        />
      </Box>

      <Typography variant="bodySmall" color="onSurfaceVariant">
        Showing {items.length} of {data?.total ?? 0} {schema?.plural_name?.toLowerCase()}
      </Typography>
    </Stack>
  );
}
