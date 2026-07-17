import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Stack,
  Typography,
} from '@mui/material';
import ArrowBack from '@mui/icons-material/ArrowBack';
import Warning from '@mui/icons-material/Warning';
import Delete from '@mui/icons-material/Delete';
import ChatBubble from '@mui/icons-material/ChatBubble';
import Group from '@mui/icons-material/Group';
import Share from '@mui/icons-material/Share';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate, Link } from '@tanstack/react-router';
import { useSchema } from '../../lib/context/schema-context';
import { dynamicItemApi } from '../../lib/api/schema-api';
import type { DeleteImpact } from '../../lib/types/api';

export function GenericDeleteImpact({
  itemType,
  item,
  impact,
}: {
  itemType: string;
  item: any;
  impact: DeleteImpact;
}) {
  const { schema } = useSchema(itemType);
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [confirmText, setConfirmText] = useState('');
  const [showError, setShowError] = useState(false);

  const displayName = schema?.display_name || itemType;
  const itemName = item.field_values?.name || item.title || `Item #${item.id}`;
  const canDelete = confirmText === itemName;

  const deleteMutation = useMutation({
    mutationFn: () => dynamicItemApi.delete(itemType, item.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['items', itemType, 'list'] });
      navigate({ to: '/items/$itemType', params: { itemType } });
    },
    onError: () => setShowError(true),
  });

  return (
    <Stack spacing={3} sx={{ maxWidth: 800 }}>
      <Stack direction="row" spacing={2} alignItems="center">
        <Button component={Link} to={`/items/${itemType}/${item.id}`} startIcon={<ArrowBack />}>
          Back to details
        </Button>
      </Stack>

      <Box>
        <Typography variant="headlineSmall" component="h1" sx={{ mb: 0.5 }}>
          Delete {displayName}
        </Typography>
        <Typography variant="bodyLarge" color="onSurfaceVariant">
          {itemName}
        </Typography>
      </Box>

      <Alert severity="error" icon={<Warning />}>
        <Typography fontWeight={500}>This action is permanent</Typography>
        <Typography variant="body2">
          Deleting this {displayName.toLowerCase()} will cascade and remove all associated data. Cannot be undone.
        </Typography>
      </Alert>

      <Card>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="titleMedium" sx={{ mb: 2 }}>Impact assessment</Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 2, mb: 3 }}>
            <ImpactBox tone="error" label="Ratings" value={impact.impact.ratings_count} icon={<ChatBubble />} />
            <ImpactBox tone="warning" label="Users affected" value={impact.impact.users_affected} icon={<Group />} />
            <ImpactBox tone="tertiary" label="Sharings" value={impact.impact.sharings_count} icon={<Share />} />
          </Box>

          {impact.warnings.length > 0 && (
            <Box sx={{ mb: 2 }}>
              <Typography variant="titleSmall" sx={{ mb: 1 }}>Important warnings</Typography>
              <Stack spacing={0.5}>
                {impact.warnings.map((w, i) => (
                  <Typography key={i} variant="bodyMedium">• {w}</Typography>
                ))}
              </Stack>
            </Box>
          )}

          {impact.impact.affected_users.length > 0 && (
            <Box>
              <Typography variant="titleSmall" sx={{ mb: 1 }}>Affected users</Typography>
              <Stack spacing={1}>
                {impact.impact.affected_users.map((u) => (
                  <Stack
                    key={u.id}
                    direction="row"
                    justifyContent="space-between"
                    alignItems="center"
                    sx={{ p: 1.5, bgcolor: 'surfaceContainerLow', borderRadius: '12px' }}
                  >
                    <Typography variant="bodyMedium" fontWeight={500}>{u.display_name}</Typography>
                    <Typography variant="bodySmall" color="onSurfaceVariant">
                      {u.ratings_count} rating{u.ratings_count !== 1 ? 's' : ''} lost
                    </Typography>
                  </Stack>
                ))}
              </Stack>
            </Box>
          )}
        </CardContent>
      </Card>

      <Card sx={{ borderColor: 'error.main', borderWidth: 1, borderStyle: 'solid' }}>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="titleMedium" color="error" sx={{ mb: 1 }}>Confirm deletion</Typography>
          <Typography variant="bodyMedium" color="onSurfaceVariant" sx={{ mb: 2 }}>
            Type <strong>{itemName}</strong> to confirm
          </Typography>
          <Box
            component="input"
            value={confirmText}
            onChange={(e: any) => setConfirmText(e.target.value)}
            placeholder={`Type "${itemName}" to confirm`}
            disabled={deleteMutation.isPending}
            sx={{
              width: '100%',
              p: 1.5,
              border: 1,
              borderColor: 'outline',
              borderRadius: '8px',
              fontSize: 14,
              fontFamily: 'inherit',
              mb: 2,
              bgcolor: 'background',
              '&:focus': { outline: 'none', borderColor: 'primary' },
            }}
          />
          {showError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {(deleteMutation.error as Error).message || 'Failed to delete'}
            </Alert>
          )}
          <Stack direction="row" spacing={1.5} justifyContent="flex-end">
            <Button variant="text" component={Link} to={`/items/${itemType}/${item.id}`}>
              Cancel
            </Button>
            <Button
              variant="contained"
              color="error"
              onClick={() => deleteMutation.mutate()}
              disabled={!canDelete || !impact.can_delete || deleteMutation.isPending}
              startIcon={deleteMutation.isPending ? <CircularProgress size={16} color="inherit" /> : <Delete />}
            >
              Delete permanently
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Stack>
  );
}

function ImpactBox({ tone, label, value, icon }: { tone: 'error' | 'warning' | 'tertiary'; label: string; value: number; icon: React.ReactNode }) {
  const bg = tone === 'error' ? 'errorContainer' : tone === 'warning' ? 'tertiaryContainer' : 'secondaryContainer';
  const fg = tone === 'error' ? 'onErrorContainer' : tone === 'warning' ? 'onTertiaryContainer' : 'onSecondaryContainer';
  return (
    <Box sx={{ p: 2, bgcolor: bg, color: fg, borderRadius: '12px' }}>
      <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
        {icon}
        <Typography variant="labelMedium">{label}</Typography>
      </Stack>
      <Typography variant="headlineMedium">{value}</Typography>
    </Box>
  );
}
