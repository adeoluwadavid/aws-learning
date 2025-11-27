import { useRef, useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { attachments } from '../lib/api';
import type { Attachment } from '../types';

interface FileAttachmentsProps {
  taskId: number;
  attachmentList: Attachment[];
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

export function FileAttachments({ taskId, attachmentList }: FileAttachmentsProps) {
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isUploading, setIsUploading] = useState(false);

  const uploadMutation = useMutation({
    mutationFn: (file: File) => attachments.upload(taskId, file),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['task', taskId] });
      setIsUploading(false);
    },
    onError: () => {
      setIsUploading(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (attachmentId: number) => attachments.delete(taskId, attachmentId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['task', taskId] });
    },
  });

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setIsUploading(true);
    for (const file of Array.from(files)) {
      await uploadMutation.mutateAsync(file);
    }

    // Reset input
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleDelete = (attachmentId: number, filename: string) => {
    if (confirm(`Delete "${filename}"?`)) {
      deleteMutation.mutate(attachmentId);
    }
  };

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <label className="block text-sm font-medium text-gray-700">
          Attachments ({attachmentList.length})
        </label>
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={isUploading}
          className="text-sm text-indigo-600 hover:text-indigo-500 disabled:opacity-50"
        >
          {isUploading ? 'Uploading...' : '+ Add file'}
        </button>
        <input
          ref={fileInputRef}
          type="file"
          multiple
          className="hidden"
          onChange={handleFileSelect}
        />
      </div>

      {attachmentList.length > 0 ? (
        <ul className="border border-gray-200 rounded-md divide-y divide-gray-200">
          {attachmentList.map((attachment) => (
            <li
              key={attachment.id}
              className="px-3 py-2 flex items-center justify-between text-sm"
            >
              <div className="flex items-center min-w-0 flex-1">
                <svg
                  className="flex-shrink-0 h-5 w-5 text-gray-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"
                  />
                </svg>
                <span className="ml-2 truncate">{attachment.filename}</span>
                <span className="ml-2 text-gray-400 flex-shrink-0">
                  ({formatFileSize(attachment.file_size)})
                </span>
              </div>
              <button
                type="button"
                onClick={() => handleDelete(attachment.id, attachment.filename)}
                disabled={deleteMutation.isPending}
                className="ml-2 text-red-500 hover:text-red-700 disabled:opacity-50"
              >
                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                  />
                </svg>
              </button>
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-gray-500 italic">No attachments yet</p>
      )}
    </div>
  );
}
