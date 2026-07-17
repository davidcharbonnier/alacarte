import { useState } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Stack,
  TextField,
  Typography,
  Dialog,
  DialogContent,
  DialogTitle,
} from '@mui/material';
import ArrowBack from '@mui/icons-material/ArrowBack';
import Warning from '@mui/icons-material/Warning';
import Delete from '@mui/icons-material/Delete';
import Person from '@mui/icons-material/Person';
import ChatBubble from '@mui/icons-material/ChatBubble';
import Group from '@mui/icons-material/Group';
import Share from '@mui/icons-material/Share';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate, Link } from '@tanstack/react-router';
import { userApi } from '../lib/api/users';

export function UserDeletePage({ id }: { id: string }) {
  const userId = parseInt(id, 10);
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [confirmText, setConfirmText] = useState('');

  const { data: user } = useQuery({
    queryKey: ['users', id],
    queryFn: () => userApi.getById(userId),
  });

  const { data: impact, isLoading } = useQuery({
    queryKey: ['users', id, 'delete-impact'],
    queryFn: () => userApi.getDeleteImpact(userId),
  });

  const deleteMutation = useMutation({
    mutationFn: () => userApi.delete(userId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['users', 'list'] });
      navigate({ to: '/users' });
    },
  });

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }
  if (!impact || !user) {
    return <Typography color="error">Failed to load delete impact data</Typography>;
  }

  const canDelete = confirmText === user.display_name;

  return (
    <Stack spacing={3} sx={{ maxWidth: 800 }}>
      <Stack direction="row" spacing={2} alignItems="center">
        <Button component={Link} to={`/users/${id}`} startIcon={<ArrowBack />}>
          Back to User
        </Button>
      </Stack>

      <Alert severity="error" icon={<Warning />}>
        <Typography variant="h6">Delete User Account</Typography>
        <Typography variant="body2">
          This action will permanently delete all user data and cannot be undone
        </Typography>
      </Alert>

      <Card variant="outlined">
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>User to be deleted</Typography>
          <Stack direction="row" spacing={2} alignItems="center">
            <Avatar src={user.avatar} sx={{ width: 48, height: 48 }}>
              <Person />
            </Avatar>
            <Box>
              <Stack direction="row" spacing={1} alignItems="center">
                <Typography variant="h6">{user.display_name}</Typography>
                {user.is_admin && <Chip size="small" color="primary" icon={<Person />} label="Admin" />}
              </Stack>
              <Typography variant="body2" color="text.secondary">{user.email}</Typography>
            </Box>
          </Stack>
        </CardContent>
      </Card>

      {impact.warnings.length > 0 && (
        <Card variant="outlined" sx={{ borderColor: 'warning.main' }}>
          <CardContent>
            <Typography variant="h6" color="warning.main" sx={{ mb: 1 }}>Warnings</Typography>
            <Stack spacing={1}>
              {impact.warnings.map((w, i) => (
                <Alert key={i} severity="warning" icon={<Warning />}>
                  {w}
                </Alert>
              ))}
            </Stack>
          </CardContent>
        </Card>
      )}

      <Card variant="outlined">
        <CardContent>
          <Typography variant="h6" sx={{ mb: 1 }}>Deletion Impact</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Overview of what will be permanently deleted
          </Typography>
          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 2 }}>
            <ImpactCard icon={<ChatBubble />} label="Ratings" value={impact.impact.ratings_count} />
            <ImpactCard icon={<Group />} label="Users Affected" value={impact.impact.users_affected} />
            <ImpactCard icon={<Share />} label="Sharing Links" value={impact.impact.sharings_count} />
          </Box>
        </CardContent>
      </Card>

      {impact.impact.affected_users && impact.impact.affected_users.length > 0 && (
        <Card variant="outlined">
          <CardContent>
            <Typography variant="h6" sx={{ mb: 1 }}>Users Who Will Lose Shared Ratings</Typography>
            <Stack spacing={1}>
              {impact.impact.affected_users.map((au) => (
                <Stack
                  key={au.id}
                  direction="row"
                  justifyContent="space-between"
                  alignItems="center"
                  sx={{ p: 1.5, bgcolor: 'action.hover', borderRadius: 1 }}
                >
                  <Typography>{au.display_name}</Typography>
                  <Chip size="small" label={`${au.ratings_count} rating${au.ratings_count !== 1 ? 's' : ''}`} />
                </Stack>
              ))}
            </Stack>
          </CardContent>
        </Card>
      )}

      <Card variant="outlined" sx={{ borderColor: 'error.main' }}>
        <CardContent>
          <Typography variant="h6" color="error.main" sx={{ mb: 1 }}>Confirm Deletion</Typography>
          <Typography variant="body2" sx={{ mb: 2 }}>
            Type the user&apos;s display name <strong>{user.display_name}</strong> to confirm
          </Typography>
          <TextField
            fullWidth
            value={confirmText}
            onChange={(e) => setConfirmText(e.target.value)}
            placeholder={`Type "${user.display_name}" to confirm`}
            disabled={deleteMutation.isPending}
            sx={{ mb: 2 }}
          />
          {deleteMutation.isError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {(deleteMutation.error as Error).message}
            </Alert>
          )}
          <Stack direction="row" spacing={2}>
            <Button
              variant="outlined"
              fullWidth
              component={Link}
              to={`/users/${id}`}
              disabled={deleteMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              variant="contained"
              color="error"
              fullWidth
              disabled={!canDelete || deleteMutation.isPending}
              onClick={() => deleteMutation.mutate()}
              startIcon={<Delete />}
            >
              Delete User Permanently
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Stack>
  );
}

function ImpactCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) {
  return (
    <Box sx={{ textAlign: 'center', p: 2, bgcolor: 'action.hover', borderRadius: 1 }}>
      <Box sx={{ color: 'text.secondary', mb: 1, display: 'flex', justifyContent: 'center' }}>{icon}</Box>
      <Typography variant="h5">{value}</Typography>
      <Typography variant="caption" color="text.secondary">{label}</Typography>
    </Box>
  );
}
